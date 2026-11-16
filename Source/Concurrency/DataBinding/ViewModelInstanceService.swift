//
//  ViewModelInstanceService.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import Combine

/// A service class that manages view model instance operations and coordinates with the command queue.
///
/// Implements `ViewModelInstanceListener` to receive callbacks from the command queue. Manages two
/// types of continuations: regular continuations for one-time value requests and stream continuations
/// for property subscriptions. All command queue operations must be performed on the main thread
/// (either marked `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched
/// to the main actor to safely access continuations.
///
/// Streams observing the same property share a native subscription. The first stream subscribes,
/// and the last stream to terminate unsubscribes.
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class ViewModelInstanceService: NSObject, ViewModelInstanceListener {
    struct DirtyEvent: Equatable, Sendable {
        let id: UInt64
    }

    private struct PropertySubscription {
        struct Key: Hashable {
            let instance: ViewModelInstance.ViewModelInstanceHandle
            let path: String
            let type: ViewModelProperty.DataType
        }

        let key: Key
        var continuations: [UInt64: AnyAsyncThrowingStreamContinuation] = [:]

        /// Returns whether the removed stream was the last one in the subscription.
        mutating func removeStream(_ streamID: UInt64) -> Bool {
            guard continuations.removeValue(forKey: streamID) != nil else { return false }
            return continuations.isEmpty
        }
    }

    private struct PropertySubscriptions {
        private var subscriptions: [UInt64: PropertySubscription] = [:]
        private var requestIDs: [PropertySubscription.Key: UInt64] = [:]

        var isEmpty: Bool {
            subscriptions.isEmpty
        }

        /// Returns the request ID to subscribe with when adding the first stream for a property.
        mutating func addStream(
            _ continuation: AnyAsyncThrowingStreamContinuation,
            streamID: UInt64,
            for property: PropertySubscription.Key
        ) -> UInt64? {
            let existingRequestID = requestIDs[property]
            let requestID = existingRequestID ?? streamID
            subscriptions[requestID, default: PropertySubscription(key: property)].continuations[streamID] = continuation
            guard existingRequestID == nil else { return nil }
            requestIDs[property] = requestID
            return requestID
        }

        func subscription(for requestID: UInt64) -> PropertySubscription? {
            subscriptions[requestID]
        }

        func subscriptionIDs(for instance: ViewModelInstance.ViewModelInstanceHandle) -> [UInt64] {
            subscriptions.compactMap { requestID, subscription in
                subscription.key.instance == instance ? requestID : nil
            }
        }

        mutating func removeSubscription(_ requestID: UInt64) -> PropertySubscription? {
            guard let subscription = subscriptions.removeValue(forKey: requestID) else { return nil }
            requestIDs.removeValue(forKey: subscription.key)
            return subscription
        }

        /// Returns the request ID to unsubscribe when removing the last stream for a property.
        mutating func removeStream(_ streamID: UInt64, for property: PropertySubscription.Key) -> UInt64? {
            guard let requestID = requestIDs[property],
                  subscriptions[requestID]?.removeStream(streamID) == true else { return nil }
            return requestID
        }
    }

    private static var nextDirtyEventID: UInt64 = 0

    let dependencies: Dependencies
    /// Regular continuations for one-time value requests (e.g., `stringValue`, `numberValue`).
    /// Resumed when `onViewModelDataReceived` is called.
    private var continuations: [UInt64: AnyContinuation] = [:]
    private var propertySubscriptions = PropertySubscriptions()
    /// Publishers for per-instance dirty events.
    private var dirtySubjects: [ViewModelInstance.ViewModelInstanceHandle: PassthroughSubject<DirtyEvent, Never>] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private func beginImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.processMessagesImmediately(requestID: requestID)
    }

    private func finishImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.callbackProcessed(requestID: requestID)
    }

    /// Wraps a continuation-based command queue operation with cancellation support.
    private func withCancellableContinuation<T: Sendable>(
        cancelledError: Error,
        operation: @escaping (UInt64) -> Void
    ) async throws -> T {
        let requestID = dependencies.commandQueue.nextRequestID
        return try await withTaskCancellationHandler {
            guard !Task.isCancelled else {
                throw cancelledError
            }
            return try await withCheckedThrowingContinuation { continuation in
                continuations[requestID] = AnyContinuation(continuation)
                beginImmediateRequest(requestID)
                operation(requestID)
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let continuation = self.continuations.removeValue(forKey: requestID) {
                    self.finishImmediateRequest(requestID)
                    continuation.resume(throwing: cancelledError)
                }
            }
        }
    }

    @MainActor
    func dirtyPublisher(for instance: ViewModelInstance.ViewModelInstanceHandle) -> AnyPublisher<DirtyEvent, Never> {
        let subject = dirtySubjects[instance] ?? PassthroughSubject<DirtyEvent, Never>()
        dirtySubjects[instance] = subject
        return subject.eraseToAnyPublisher()
    }

    @MainActor
    func hasActiveListeners() -> Bool {
        !propertySubscriptions.isEmpty
    }

    private func propertyStream<Value: Sendable>(
        for instance: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        type: ViewModelProperty.DataType
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let streamID = commandQueue.nextRequestID
            let property = PropertySubscription.Key(instance: instance, path: path, type: type)
            let requestID = propertySubscriptions.addStream(
                AnyAsyncThrowingStreamContinuation(continuation),
                streamID: streamID,
                for: property
            )

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.streamDidTerminate(streamID, for: property)
                }
            }

            if let requestID {
                commandQueue.subscribe(toViewModelProperty: instance, path: path, type: type.objcValue, requestID: requestID)
            }
        }
    }

    private func streamDidTerminate(_ streamID: UInt64, for property: PropertySubscription.Key) {
        if let requestID = propertySubscriptions.removeStream(streamID, for: property) {
            endPropertySubscription(requestID)
        }
    }

    private func endPropertySubscription(_ requestID: UInt64, error: Error? = nil) {
        guard let subscription = propertySubscriptions.removeSubscription(requestID) else { return }
        let property = subscription.key
        dependencies.commandQueue.unsubscribe(
            toViewModelProperty: property.instance,
            path: property.path,
            type: property.type.objcValue,
            requestID: requestID
        )
        for continuation in subscription.continuations.values {
            continuation.finish(throwing: error)
        }
    }

    @MainActor
    private func emitDirty(for instance: ViewModelInstance.ViewModelInstanceHandle) {
        guard let subject = dirtySubjects[instance] else { return }
        let event = DirtyEvent(id: Self.nextDirtyEventID)
        Self.nextDirtyEventID &+= 1
        subject.send(event)
    }
    
    private static func context(_ instance: ViewModelInstance.ViewModelInstanceHandle) -> String {
        "[ViewModelInstance (\(instance))]"
    }

    /// Deletes a view model instance via the command queue.
    ///
    /// The continuation is resumed when `onViewModelDeleted` is called.
    ///
    /// - Parameter instance: The view model instance handle to delete
    /// - Returns: The view model instance handle that was deleted
    @MainActor
    func deleteViewModelInstance(_ instance: ViewModelInstance.ViewModelInstanceHandle) async throws -> ViewModelInstance.ViewModelInstanceHandle {
        RiveLog.debug(tag: .viewModelInstance, "\(Self.context(instance)) Deleting instance")
        return try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            for subscriptionID in self.propertySubscriptions.subscriptionIDs(for: instance) {
                self.endPropertySubscription(subscriptionID)
            }
            self.dependencies.commandQueue.deleteViewModelInstance(instance, requestID: requestID)
        }
    }

    /// Deletes a view model instance listener via the command queue.
    ///
    /// - Parameter instance: The view model instance handle whose listener should be removed
    @MainActor
    func deleteViewModelInstanceListener(_ instance: ViewModelInstance.ViewModelInstanceHandle) {
        dependencies.commandQueue.deleteViewModelInstanceListener(instance)
        dirtySubjects.removeValue(forKey: instance)?.send(completion: .finished)
    }

    // MARK: - Names

    /// Retrieves the name of the view model that defines the instance.
    ///
    /// The continuation is resumed when `onViewModelInstanceViewModelNameReceived` is called.
    ///
    /// - Parameter instance: The view model instance handle
    /// - Returns: The name of the view model that defines the instance
    /// - Throws: `ViewModelInstanceError` if the request fails
    @MainActor
    func viewModelName(for instance: ViewModelInstance.ViewModelInstanceHandle) async throws -> String {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceViewModelName(instance, requestID: requestID)
        }
    }

    /// Retrieves the editor-assigned name of the instance.
    ///
    /// The continuation is resumed when `onViewModelInstanceNameReceived` is called.
    ///
    /// - Parameter instance: The view model instance handle
    /// - Returns: The editor-assigned name of the instance, or an empty string for instances
    ///   without a name (e.g. blank instances)
    /// - Throws: `ViewModelInstanceError` if the request fails
    @MainActor
    func name(for instance: ViewModelInstance.ViewModelInstanceHandle) async throws -> String {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceName(instance, requestID: requestID)
        }
    }

    // MARK: - StringProperty

    /// Retrieves a string property value.
    ///
    /// The continuation is resumed when `onViewModelDataReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The string property value
    /// - Throws: `ViewModelInstanceError.missingData` if the property value is missing or invalid
    @MainActor
    func stringValue(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> String {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceString(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits string property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. The last stream to terminate unsubscribes.
    @MainActor
    func stringValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<String, Error> {
        propertyStream(for: instance, path: path, type: .string)
    }

    /// Sets a string property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setStringValue(_ value: String, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceString(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - NumberProperty

    /// Retrieves a number property value.
    ///
    /// The continuation is resumed when `onViewModelDataReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The number property value
    /// - Throws: `ViewModelInstanceError.missingData` if the property value is missing or invalid
    @MainActor
    func numberValue(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> Float {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceNumber(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits number property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. The last stream to terminate unsubscribes.
    @MainActor
    func numberValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Float, Error> {
        propertyStream(for: instance, path: path, type: .number)
    }

    /// Sets a number property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setNumberValue(_ value: Float, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceNumber(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - BoolProperty

    /// Retrieves a boolean property value.
    ///
    /// The continuation is resumed when `onViewModelDataReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The boolean property value
    /// - Throws: `ViewModelInstanceError.missingData` if the property value is missing or invalid
    @MainActor
    func boolValue(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> Bool {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceBool(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits boolean property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. The last stream to terminate unsubscribes.
    @MainActor
    func boolValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Bool, Error> {
        propertyStream(for: instance, path: path, type: .boolean)
    }

    /// Sets a boolean property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setBoolValue(_ value: Bool, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceBool(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - ColorProperty

    /// Retrieves a color property value.
    ///
    /// The continuation is resumed when `onViewModelDataReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The color property value
    /// - Throws: `ViewModelInstanceError.missingData` if the property value is missing or invalid
    @MainActor
    func colorValue(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> Color {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceColor(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits color property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. The last stream to terminate unsubscribes.
    @MainActor
    func colorValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Color, Error> {
        propertyStream(for: instance, path: path, type: .color)
    }

    /// Sets a color property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setColorValue(_ value: Color, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceColor(instance, path: path, value: value.argbValue, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - EnumProperty

    /// Retrieves an enum property value.
    ///
    /// The continuation is resumed when `onViewModelDataReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The enum property value
    /// - Throws: `ViewModelInstanceError.missingData` if the property value is missing or invalid
    @MainActor
    func enumValue(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> String {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceEnum(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits enum property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. The last stream to terminate unsubscribes.
    @MainActor
    func enumValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<String, Error> {
        propertyStream(for: instance, path: path, type: .enum)
    }

    /// Sets an enum property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setEnumValue(_ value: String, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceEnum(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - TriggerProperty

    /// Fires a trigger property.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func fireTrigger(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.fireViewModelTrigger(instance, path: path, requestID: requestID)
        emitDirty(for: instance)
    }

    /// Creates a stream that emits events when a trigger property is fired.
    ///
    /// Subscribes to trigger events via the command queue. Events are yielded when
    /// `onViewModelDataReceived` is called with a trigger type. The last stream to terminate unsubscribes.
    @MainActor
    func triggerStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Void, Error> {
        propertyStream(for: instance, path: path, type: .trigger)
    }

    // MARK: - ImageProperty

    /// Sets an image property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setImageValue(_ value: Image.ImageHandle, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceImage(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - FontProperty

    /// Sets a font property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setFontValue(_ value: Font.FontHandle, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceFont(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - BlobProperty

    /// Sets a blob property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setBlobValue(_ value: Blob.BlobHandle, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceBlob(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - ArtboardProperty

    /// Sets an artboard property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setArtboardValue(_ value: Artboard?, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceArtboard(instance, path: path, value: value?.artboardHandle ?? 0, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - ViewModelInstanceProperty

    /// Retrieves a nested view model instance property value.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// The provided observer receives callbacks for the nested instance.
    func viewModelInstanceValue(
        for instance: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        observer: ViewModelInstanceListener
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        return dependencies.commandQueue.referenceNestedViewModelInstance(instance, path: path, observer: observer, requestID: requestID)
    }

    /// Sets a view model instance property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setViewModelInstanceValue(_ value: ViewModelInstance.ViewModelInstanceHandle, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceNestedViewModel(instance, path: path, value: value, requestID: requestID)
        emitDirty(for: instance)
    }

    // MARK: - ListProperty

    /// Retrieves the size of a list property.
    ///
    /// The continuation is resumed when `onViewModelListSizeReceived` is called.
    ///
    /// - Parameters:
    ///   - instance: The view model instance handle
    ///   - path: The property path
    /// - Returns: The size of the list property
    /// - Throws: `ViewModelInstanceError` if the request fails
    @MainActor
    func listSize(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) async throws -> Int {
        try await withCancellableContinuation(cancelledError: ViewModelInstanceError.cancelled) { requestID in
            self.dependencies.commandQueue.requestViewModelInstanceListSize(instance, path: path, requestID: requestID)
        }
    }

    /// Retrieves a view model instance from a list property at the specified index.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// The provided observer receives callbacks for the list item instance.
    @MainActor
    func listViewModelInstanceValue(
        for instance: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        index: Int32,
        observer: ViewModelInstanceListener
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        return dependencies.commandQueue.referenceListViewModelInstance(
            instance,
            path: path,
            index: index,
            observer: observer,
            requestID: requestID
        )
    }

    /// Appends a view model instance to a list property.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func appendViewModelInstance(
        _ base: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        value: ViewModelInstance.ViewModelInstanceHandle
    ) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.appendViewModelInstanceListViewModel(
            base,
            path: path,
            value: value,
            requestID: requestID
        )
        emitDirty(for: base)
    }

    /// Inserts a view model instance into a list property at the specified index.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func insertViewModelInstance(
        _ base: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        value: ViewModelInstance.ViewModelInstanceHandle,
        index: Int32
    ) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.insertViewModelInstanceListViewModel(
            base,
            path: path,
            value: value,
            index: index,
            requestID: requestID
        )
        emitDirty(for: base)
    }

    /// Removes a view model instance from a list property at the specified index.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func removeViewModelInstanceListViewModelAtIndex(
        _ base: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        index: Int32,
        value: ViewModelInstance.ViewModelInstanceHandle
    ) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.removeViewModelInstanceListViewModelAtIndex(
            base,
            path: path,
            index: index,
            value: value,
            requestID: requestID
        )
        emitDirty(for: base)
    }

    /// Removes a view model instance from a list property by value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func removeViewModelInstanceListViewModelByValue(
        _ base: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        value: ViewModelInstance.ViewModelInstanceHandle
    ) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.removeViewModelInstanceListViewModelByValue(
            base,
            path: path,
            value: value,
            requestID: requestID
        )
        emitDirty(for: base)
    }

    /// Swaps two view model instances in a list property at the specified indices.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func swapViewModelInstanceListValues(
        _ base: ViewModelInstance.ViewModelInstanceHandle,
        path: String,
        atIndex: Int32,
        withIndex: Int32
    ) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.swapViewModelInstanceListValues(
            base,
            path: path,
            atIndex: atIndex,
            withIndex: withIndex,
            requestID: requestID
        )
        emitDirty(for: base)
    }

    /// Called when a view model instance operation encounters an error.
    ///
    /// Listener callback invoked by the command server when an operation fails.
    nonisolated public func onViewModelInstanceError(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        message: String
    ) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            RiveLog.error(tag: .viewModelInstance, "\(Self.context(viewModelInstanceHandle)) Operation failed: \(message)")
            if let continuation = continuations.removeValue(forKey: requestID) {
                continuation.resume(
                    throwing: ViewModelInstanceError.message(message)
                )
            } else {
                endPropertySubscription(requestID, error: ViewModelInstanceError.message(message))
            }
        }
    }

    /// Called when view model data is received.
    ///
    /// Listener callback invoked by the command server. Handles both regular continuations
    /// (one-time value requests) and stream continuations (property subscriptions). For streams,
    /// values are yielded as they arrive. Dispatches to main actor to safely access continuations.
    nonisolated public func onViewModelDataReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        data: [String: Any]
    ) {
        let viewModelInstanceData = ViewModelInstanceData(from: data)
        Task { @MainActor in
            let subscription = propertySubscriptions.subscription(for: requestID)
            if subscription == nil {
                finishImmediateRequest(requestID)
            }
            let continuation = continuations.removeValue(forKey: requestID)
            guard continuation != nil || subscription != nil else { return }

            do {
                let value: any Sendable
                switch viewModelInstanceData.type {
                case .trigger:
                    guard continuation == nil else { throw ViewModelInstanceError.missingData }
                    value = ()
                case .value(.string(let stringValue)):
                    value = stringValue
                case .value(.number(let numberValue)):
                    value = numberValue
                case .value(.boolean(let booleanValue)):
                    value = booleanValue
                case .value(.color(let argbValue)):
                    value = Color(argbValue)
                case .value(.none):
                    throw ViewModelInstanceError.missingData
                }

                if let continuation {
                    try continuation.resume(returning: value)
                } else if let subscription {
                    for stream in subscription.continuations.values {
                        try stream.yield(value)
                    }
                }
            } catch {
                let deliveryError: ViewModelInstanceError
                switch error {
                case let error as ViewModelInstanceError:
                    deliveryError = error
                case AnyContinuationError.typeMismatch(let expected, let actual),
                     AnyAsyncThrowingStreamContinuationError.typeMismatch(let expected, let actual):
                    deliveryError = .valueMismatch(expected, actual)
                default:
                    deliveryError = .error(error)
                }

                if let continuation {
                    continuation.resume(throwing: deliveryError)
                } else {
                    endPropertySubscription(requestID, error: deliveryError)
                }
            }
        }
    }

    /// Called when view model list size is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the list size.
    nonisolated public func onViewModelListSizeReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        path: String,
        size: Int
    ) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            if let continuation = continuations.removeValue(forKey: requestID) {
                RiveLog.trace(tag: .viewModelInstance, "\(Self.context(viewModelInstanceHandle)) Received list size \(size) for path '\(path)'")
                try continuation.resume(returning: size)
            }
        }
    }

    /// Called when a view model instance's view model (definition) name is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the view model name.
    nonisolated public func onViewModelInstanceViewModelNameReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        viewModelName: String
    ) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            if let continuation = continuations.removeValue(forKey: requestID) {
                RiveLog.trace(tag: .viewModelInstance, "\(Self.context(viewModelInstanceHandle)) Received view model name '\(viewModelName)'")
                try continuation.resume(returning: viewModelName)
            }
        }
    }

    /// Called when a view model instance's editor-assigned name is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the instance name.
    nonisolated public func onViewModelInstanceNameReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        name: String
    ) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            if let continuation = continuations.removeValue(forKey: requestID) {
                RiveLog.trace(tag: .viewModelInstance, "\(Self.context(viewModelInstanceHandle)) Received instance name '\(name)'")
                try continuation.resume(returning: name)
            }
        }
    }

    /// Called when a view model instance deletion operation completes.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the deleted handle.
    nonisolated public func onViewModelDeleted(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64
    ) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            if let continuation = continuations.removeValue(forKey: requestID) {
                RiveLog.debug(tag: .viewModelInstance, "\(Self.context(viewModelInstanceHandle)) Deleted instance")
                try continuation.resume(returning: viewModelInstanceHandle)
            }
        }
    }
}

extension ViewModelInstanceService {
    /// Container for all dependencies required by the view model instance service.
    struct Dependencies {
        /// The command queue used to send view model instance-related commands to the C++ runtime.
        /// The service registers itself as a `ViewModelInstanceListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: any CommandQueueProtocol
        let messageGate: CommandQueueMessageGate

        init(commandQueue: any CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}
