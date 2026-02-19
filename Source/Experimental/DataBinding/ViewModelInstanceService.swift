//
//  ViewModelInstanceService.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages view model instance operations and coordinates with the command queue.
///
/// Implements `ViewModelInstanceListener` to receive callbacks from the command queue. Manages two
/// types of continuations: regular continuations for one-time value requests and stream continuations
/// for property subscriptions. All command queue operations must be performed on the main thread
/// (either marked `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched
/// to the main actor to safely access continuations.
///
/// The service handles property subscriptions via `subscribe`/`unsubscribe` commands. When a stream
/// is terminated, the `onTermination` handler automatically unsubscribes and cleans up the stream continuation.
@MainActor
class ViewModelInstanceService: NSObject, ViewModelInstanceListener {
    let dependencies: Dependencies
    /// Regular continuations for one-time value requests (e.g., `stringValue`, `numberValue`).
    /// Resumed when `onViewModelDataReceived` is called.
    private var continuations: [UInt64: AnyContinuation] = [:]
    /// Stream continuations for property subscriptions (e.g., `stringValueStream`, `numberValueStream`).
    /// Yielded values when `onViewModelDataReceived` is called. Cleaned up when streams terminate.
    private var streamContinuations: [UInt64: AnyAsyncThrowingStreamContinuation] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Name

    /// Retrieves the name of a view model instance.
    ///
    /// The continuation is resumed when `onViewModelInstanceNameReceived` is called.
    ///
    /// - Parameter instance: The view model instance handle
    /// - Returns: The name of the view model instance
    @MainActor
    func name(for instance: ViewModelInstance.ViewModelInstanceHandle) async throws -> String {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceName(instance, requestID: requestID)
        }
    }

    /// Creates a blank view model instance from an artboard.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createBlankViewModelInstance(
        for artboard: Artboard,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createBlankViewModelInstance(
            forArtboard: artboard.artboardHandle,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Creates a blank view model instance by view model name.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createBlankViewModelInstance(
        named viewModelName: String,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createBlankViewModelInstanceNamed(
            viewModelName,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Creates a default view model instance from an artboard.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createDefaultViewModelInstance(
        for artboard: Artboard,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createDefaultViewModelInstance(
            forArtboard: artboard.artboardHandle,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Creates a default view model instance by view model name.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createDefaultViewModelInstance(
        named viewModelName: String,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createDefaultViewModelInstanceNamed(
            viewModelName,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Creates a named view model instance from an artboard.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createViewModelInstanceNamed(
        _ instanceName: String,
        for artboard: Artboard,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createViewModelInstanceNamed(
            instanceName,
            forArtboard: artboard.artboardHandle,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Creates a named view model instance by view model name.
    ///
    /// Delegates to the command queue. Returns immediately with the instance handle.
    /// No listener callback is invoked for this operation.
    @MainActor
    func createViewModelInstanceNamed(
        _ instanceName: String,
        viewModelName: String,
        from file: File
    ) -> ViewModelInstance.ViewModelInstanceHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        let handle = dependencies.commandQueue.createViewModelInstanceNamed(
            instanceName,
            viewModelName: viewModelName,
            fromFile: file.fileHandle,
            observer: self,
            requestID: requestID
        )
        return handle
    }

    /// Deletes a view model instance via the command queue.
    ///
    /// After deletion, the instance handle becomes invalid. This operation is irreversible.
    /// No listener callback is invoked for this operation.
    @MainActor
    func deleteViewModelInstance(_ instance: ViewModelInstance.ViewModelInstanceHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.deleteViewModelInstance(instance, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceString(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits string property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. Automatically unsubscribes when the stream terminates.
    @MainActor
    func stringValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .string, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .string, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Sets a string property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setStringValue(_ value: String, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceString(instance, path: path, value: value, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceNumber(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits number property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. Automatically unsubscribes when the stream terminates.
    @MainActor
    func numberValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Float, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .number, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .number, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Sets a number property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setNumberValue(_ value: Float, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceNumber(instance, path: path, value: value, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceBool(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits boolean property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. Automatically unsubscribes when the stream terminates.
    @MainActor
    func boolValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Bool, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .boolean, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .boolean, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Sets a boolean property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setBoolValue(_ value: Bool, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceBool(instance, path: path, value: value, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceColor(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits color property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. Automatically unsubscribes when the stream terminates.
    @MainActor
    func colorValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Color, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .color, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .color, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Sets a color property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setColorValue(_ value: Color, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceColor(instance, path: path, value: value.argbValue, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceEnum(instance, path: path, requestID: requestID)
        }
    }

    /// Creates a stream that emits enum property values as they change.
    ///
    /// Subscribes to property changes via the command queue. Values are yielded when
    /// `onViewModelDataReceived` is called. Automatically unsubscribes when the stream terminates.
    @MainActor
    func enumValueStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .enum, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .enum, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Sets an enum property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setEnumValue(_ value: String, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceEnum(instance, path: path, value: value, requestID: requestID)
    }

    // MARK: - TriggerProperty

    /// Fires a trigger property.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func fireTrigger(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.fireViewModelTrigger(instance, path: path, requestID: requestID)
    }

    /// Creates a stream that emits events when a trigger property is fired.
    ///
    /// Subscribes to trigger events via the command queue. Events are yielded when
    /// `onViewModelDataReceived` is called with a trigger type. Automatically unsubscribes when the stream terminates.
    @MainActor
    func triggerStream(for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) -> AsyncThrowingStream<Void, Error> {
        return AsyncThrowingStream { continuation in
            let commandQueue = dependencies.commandQueue
            let requestID = commandQueue.nextRequestID
            streamContinuations[requestID] = AnyAsyncThrowingStreamContinuation(continuation)
            commandQueue.subscribe(toViewModelProperty: instance, path: path, type: .trigger, requestID: requestID)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    commandQueue.unsubscribe(toViewModelProperty: instance, path: path, type: .trigger, requestID: requestID)
                    guard let self else { return }
                    self.streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    // MARK: - ImageProperty

    /// Sets an image property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setImageValue(_ value: Image.ImageHandle, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceImage(instance, path: path, value: value, requestID: requestID)
    }

    // MARK: - ArtboardProperty

    /// Sets an artboard property value.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setArtboardValue(_ value: Artboard, for instance: ViewModelInstance.ViewModelInstanceHandle, path: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstanceArtboard(instance, path: path, value: value.artboardHandle, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceListSize(instance, path: path, requestID: requestID)
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
    }

    /// Called when view model data is received.
    ///
    /// Listener callback invoked by the command server. Handles both regular continuations
    /// (one-time value requests) and stream continuations (property subscriptions). For streams,
    /// values are yielded as they arrive. Dispatches to main actor to safely access continuations.
    nonisolated public func onViewModelDataReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        data: RiveViewModelInstanceData
    ) {
        Task { @MainActor in
            if let continuation = continuations.removeValue(forKey: requestID) {
                do {
                    if let stringValue = data.stringValue {
                        try continuation.resume(with: .success(stringValue))
                    } else if let numberValue = data.numberValue {
                        try continuation.resume(with: .success(numberValue.floatValue))
                    } else if let boolValue = data.boolValue {
                        try continuation.resume(with: .success(boolValue.boolValue))
                    } else if let colorValue = data.colorValue {
                        let argbValue = colorValue.uint32Value
                        try continuation.resume(with: .success(Color(argbValue)))
                    } else {
                        try continuation.resume(with: .failure(ViewModelInstanceError.missingData))
                    }
                } catch AnyContinuationError.typeMismatch(expected: let expected, actual: let actual) {
                    try continuation.resume(with: .failure(ViewModelInstanceError.valueMismatch(expected, actual)))
                }
                return
            }
            
            if let streamContinuation = streamContinuations[requestID] {
                do {
                    // Trigger is a special case where we want to yield ()
                    // and ignore any data values
                    if case .trigger = data.type {
                        try streamContinuation.yield(())
                    } else {
                        if let stringValue = data.stringValue {
                            try streamContinuation.yield(stringValue)
                        } else if let numberValue = data.numberValue {
                            try streamContinuation.yield(numberValue.floatValue)
                        } else if let boolValue = data.boolValue {
                            try streamContinuation.yield(boolValue.boolValue)
                        } else if let colorValue = data.colorValue {
                            let argbValue = colorValue.uint32Value
                            try streamContinuation.yield(Color(argbValue))
                        } else {
                            streamContinuation.finish(throwing: ViewModelInstanceError.missingData)
                            streamContinuations.removeValue(forKey: requestID)
                        }
                    }
                } catch AnyAsyncThrowingStreamContinuationError.typeMismatch(expected: let expected, actual: let actual) {
                    streamContinuation.finish(throwing: ViewModelInstanceError.valueMismatch(expected, actual))
                    streamContinuations.removeValue(forKey: requestID)
                } catch {
                    streamContinuation.finish(throwing: ViewModelInstanceError.error(error))
                    streamContinuations.removeValue(forKey: requestID)
                }
            }
        }
    }

    /// Called when a view model instance name is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the instance name.
    nonisolated public func onViewModelInstanceNameReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        name: String
    ) {
        Task { @MainActor in
            if let continuation = continuations.removeValue(forKey: requestID) {
                try continuation.resume(with: .success(name))
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
            if let continuation = continuations.removeValue(forKey: requestID) {
                try continuation.resume(with: .success(size))
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
    }
}
