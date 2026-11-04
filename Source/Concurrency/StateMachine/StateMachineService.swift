//
//  RiveUIStateMachineService.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages state machine operations and coordinates with the command queue.
///
/// Handles state machine creation, advancement, deletion, and view model binding. All command queue
/// operations must be performed on the main thread (either marked `@MainActor` or dispatched to the
/// main queue).
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class StateMachineService: NSObject, StateMachineListener {
    let dependencies: Dependencies
    private struct PendingRequest {
        let continuation: AnyContinuation
        var handle: UInt64?
    }

    private var requests: [UInt64: PendingRequest] = [:]
    private var settledContinuations: [UInt64: [UUID: AsyncStream<Void>.Continuation]] = [:]
    private var semanticsDiffContinuations: [UInt64: [UUID: AsyncStream<SemanticsDiff>.Continuation]] = [:]

    #if TESTING
    var onContinuationRemoved: (() -> Void)?
    var onRequestCancelled: ((UInt64) -> Void)?
    /// Signals that a late focus response was discarded after its request ended.
    var onFocusResponseDiscarded: ((UInt64) -> Void)?
    #endif

    private static func context(_ stateMachine: StateMachine.StateMachineHandle) -> String {
        "[StateMachine (\(stateMachine))]"
    }

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
    }

    private func beginImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.processMessagesImmediately(requestID: requestID)
    }

    private func finishImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.callbackProcessed(requestID: requestID)
    }

    /// Wraps a continuation-based command queue operation with cancellation support.
    ///
    /// Checked continuations are not resumed automatically when their task is
    /// cancelled. The cancellation handler removes and resumes the stored
    /// continuation so it cannot remain suspended indefinitely.
    private func withCancellableContinuation<T: Sendable>(
        cancelledError: Error,
        operation: @escaping (UInt64) -> UInt64?
    ) async throws -> T {
        let requestID = dependencies.commandQueue.nextRequestID
        return try await withTaskCancellationHandler {
            guard Task.isCancelled == false else {
                throw cancelledError
            }
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
                requests[requestID] = PendingRequest(
                    continuation: AnyContinuation(continuation),
                    handle: nil
                )
                beginImmediateRequest(requestID)
                requests[requestID]?.handle = operation(requestID)
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let request = self.requests.removeValue(forKey: requestID) {
                    self.finishImmediateRequest(requestID)
                    if let handle = request.handle {
                        let deletionRequestID = self.dependencies.commandQueue.nextRequestID
                        self.dependencies.commandQueue.deleteViewModelInstance(handle, requestID: deletionRequestID)
                        self.dependencies.commandQueue.deleteViewModelInstanceListener(handle)
                    }
                    request.continuation.resume(throwing: cancelledError)
                    #if TESTING
                    self.onRequestCancelled?(requestID)
                    #endif
                }
            }
        }
    }

    /// Advances a state machine by the specified time interval.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - stateMachine: The handle of the state machine to advance.
    ///   - time: The time interval to advance the state machine by.
    @MainActor
    func advanceStateMachine(_ stateMachine: StateMachine.StateMachineHandle, by time: TimeInterval) {
        RiveLog.trace(tag: .stateMachine, "\(Self.context(stateMachine)) Advancing state machine (dt=\(time))")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.advanceStateMachine(stateMachine, by: time, requestID: requestID)
    }

    @MainActor
    func settledStream(for stateMachine: StateMachine.StateMachineHandle) -> AsyncStream<Void> {
        return AsyncStream { continuation in
            let continuationID = UUID()
            var continuationsForStateMachine = settledContinuations[stateMachine] ?? [:]
            continuationsForStateMachine[continuationID] = continuation
            settledContinuations[stateMachine] = continuationsForStateMachine
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    guard var continuations = self.settledContinuations[stateMachine] else { return }
                    continuations.removeValue(forKey: continuationID)
                    if continuations.isEmpty {
                        self.settledContinuations.removeValue(forKey: stateMachine)
                    } else {
                        self.settledContinuations[stateMachine] = continuations
                    }
                }
            }
        }
    }

    @MainActor
    func semanticsDiffStream(for stateMachine: StateMachine.StateMachineHandle) -> AsyncStream<SemanticsDiff> {
        return AsyncStream { continuation in
            let continuationID = UUID()
            var continuationsForStateMachine = semanticsDiffContinuations[stateMachine] ?? [:]
            continuationsForStateMachine[continuationID] = continuation
            semanticsDiffContinuations[stateMachine] = continuationsForStateMachine
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    guard var continuations = self.semanticsDiffContinuations[stateMachine] else { return }
                    continuations.removeValue(forKey: continuationID)
                    if continuations.isEmpty {
                        self.semanticsDiffContinuations.removeValue(forKey: stateMachine)
                    } else {
                        self.semanticsDiffContinuations[stateMachine] = continuations
                    }

                    #if TESTING
                    self.onContinuationRemoved?()
                    #endif
                }
            }
        }
    }

    @MainActor
    func enableSemantics(for stateMachine: StateMachine.StateMachineHandle) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Enabling semantics")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.enableSemantics(stateMachine, requestID: requestID)
    }

    @MainActor
    func drainSemanticsDiff(for stateMachine: StateMachine.StateMachineHandle, fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: Float, viewBounds: CGSize) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Draining semantics diff")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.drainSemanticsDiff(stateMachine, fit: fit, alignment: alignment, scaleFactor: scaleFactor, viewBounds: viewBounds, requestID: requestID)
    }

    @MainActor
    func fireSemanticAction(on stateMachine: StateMachine.StateMachineHandle, nodeID: UInt32, actionType: SemanticActionType) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Firing semantic action \(actionType) on node \(nodeID)")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.fireSemanticAction(stateMachine, semanticNodeID: nodeID, actionType: actionType, requestID: requestID)
    }

    @MainActor
    func requestSemanticFocus(on stateMachine: StateMachine.StateMachineHandle, nodeID: UInt32) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Requesting semantic focus on node \(nodeID)")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.requestSemanticFocus(stateMachine, semanticNodeID: nodeID, requestID: requestID)
    }

    @MainActor
    func clearSemanticFocus(on stateMachine: StateMachine.StateMachineHandle) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Clearing semantic focus")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.clearSemanticFocus(stateMachine, requestID: requestID)
    }

    @MainActor
    func hasActiveListeners() -> Bool {
        return !settledContinuations.isEmpty || !semanticsDiffContinuations.isEmpty
    }

    /// Deletes a state machine via the command queue.
    ///
    /// The continuation is resumed when `onStateMachineDeleted` is called.
    @MainActor
    func deleteStateMachine(_ stateMachine: StateMachine.StateMachineHandle) async throws -> StateMachine.StateMachineHandle {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Deleting state machine")
        return try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            self.dependencies.commandQueue.deleteStateMachine(stateMachine, requestID: requestID)
            return nil
        }
    }

    @MainActor
    func deleteStateMachineListener(_ stateMachine: StateMachine.StateMachineHandle) {
        dependencies.commandQueue.deleteStateMachineListener(stateMachine)
    }

    /// Binds a view model instance to a state machine.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - stateMachine: The handle of the state machine to bind to.
    ///   - viewModelInstance: The handle of the view model instance to bind.
    @MainActor
    func bindViewModelInstance(_ stateMachine: StateMachine.StateMachineHandle, to viewModelInstance: ViewModelInstance.ViewModelInstanceHandle) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Binding view model instance")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.bindViewModelInstance(stateMachine, toViewModelInstance: viewModelInstance, requestID: requestID)
    }

    /// Updates the main view model instance without running the final bind pass.
    @MainActor
    func setViewModelInstance(_ stateMachine: StateMachine.StateMachineHandle, to viewModelInstance: ViewModelInstance.ViewModelInstanceHandle) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Setting main view model instance")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setViewModelInstance(stateMachine, toViewModelInstance: viewModelInstance, requestID: requestID)
    }

    /// Retrieves the main view model instance currently bound to a state machine.
    ///
    /// The observer is registered for subsequent operations on the returned view model instance.
    @MainActor
    func mainViewModelInstance(
        for stateMachine: StateMachine.StateMachineHandle,
        observer: ViewModelInstanceListener
    ) async throws -> ViewModelInstance.ViewModelInstanceHandle {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Requesting main view model instance")
        return try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            return self.dependencies.commandQueue.mainViewModelInstance(
                stateMachine,
                observer: observer,
                requestID: requestID
            )
        }
    }

    /// Updates a global view model instance without running the final bind pass.
    @MainActor
    func setGlobalViewModelInstance(
        _ stateMachine: StateMachine.StateMachineHandle,
        named name: String,
        to viewModelInstance: ViewModelInstance.ViewModelInstanceHandle
    ) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Setting global view model instance '\(name)'")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setGlobalViewModelInstance(
            stateMachine,
            named: name,
            toViewModelInstance: viewModelInstance,
            requestID: requestID
        )
    }

    /// Retrieves the view model instance currently bound to a named global slot.
    ///
    /// The observer is registered for subsequent operations on the returned view model instance.
    @MainActor
    func globalViewModelInstance(
        for stateMachine: StateMachine.StateMachineHandle,
        named name: String,
        observer: ViewModelInstanceListener
    ) async throws -> ViewModelInstance.ViewModelInstanceHandle {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Requesting global view model instance '\(name)'")
        return try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            return self.dependencies.commandQueue.globalViewModelInstance(
                stateMachine,
                named: name,
                observer: observer,
                requestID: requestID
            )
        }
    }

    /// Completes and applies the current main and global view model instances.
    @MainActor
    func bind(_ stateMachine: StateMachine.StateMachineHandle) {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Binding view model instances")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.bind(stateMachine, requestID: requestID)
    }

    /// Returns movement and post-traversal state from the command queue.
    func focusNextWithResultSynchronized(
        _ stateMachine: StateMachine.StateMachineHandle
    ) -> StateMachine.FocusTraversalResult {
        let result = dependencies.commandQueue.focusNextWithResultSynchronized(stateMachine)
        return .init(moved: result.moved, focusState: .init(
            hasFocus: result.focusState.hasFocus,
            expectsKeyboardInput: result.focusState.expectsKeyboardInput
        ))
    }

    /// Returns movement and post-traversal state from the command queue.
    func focusPreviousWithResultSynchronized(
        _ stateMachine: StateMachine.StateMachineHandle
    ) -> StateMachine.FocusTraversalResult {
        let result = dependencies.commandQueue.focusPreviousWithResultSynchronized(stateMachine)
        return .init(moved: result.moved, focusState: .init(
            hasFocus: result.focusState.hasFocus,
            expectsKeyboardInput: result.focusState.expectsKeyboardInput
        ))
    }

    /// Forwards a keyboard event and returns its synchronous consumption result.
    func keyInputSynchronized(
        _ stateMachine: StateMachine.StateMachineHandle,
        key: StateMachine.Key,
        modifiers: StateMachine.KeyModifiers,
        isPressed: Bool,
        isRepeat: Bool
    ) -> Bool {
        dependencies.commandQueue.keyInputSynchronized(
            stateMachine, key: key, modifiers: modifiers,
            isPressed: isPressed, isRepeat: isRepeat
        )
    }

    /// Forwards a spatial direction and returns its synchronous movement result.
    func focusInDirectionSynchronized(
        _ stateMachine: StateMachine.StateMachineHandle,
        direction: StateMachine.FocusDirection
    ) -> Bool {
        dependencies.commandQueue.focusInDirectionSynchronized(stateMachine, direction: direction)
    }

    func hasFocusNodes(_ stateMachine: StateMachine.StateMachineHandle) async throws -> Bool {
        try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            self.dependencies.commandQueue.requestHasFocusNodes(stateMachine, requestID: requestID)
            return nil
        }
    }

    func requestFocusState(_ stateMachine: StateMachine.StateMachineHandle) async throws -> StateMachine.FocusState {
        try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            self.dependencies.commandQueue.requestFocusState(stateMachine, requestID: requestID)
            return nil
        }
    }

    func clearFocus(_ stateMachine: StateMachine.StateMachineHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.clearFocus(stateMachine, requestID: requestID)
    }

    nonisolated func onStateMachineError(_ stateMachineHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            RiveLog.error(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Operation failed: \(message)")
            guard let request = requests.removeValue(forKey: requestID) else {
                return
            }

            finishImmediateRequest(requestID)
            if let handle = request.handle {
                dependencies.commandQueue.deleteViewModelInstanceListener(handle)
            }
            request.continuation.resume(throwing: StateMachineError.error(message))
        }
    }

    nonisolated func onStateMachineDeleted(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let request = requests.removeValue(forKey: requestID) else {
                return
            }

            finishImmediateRequest(requestID)
            RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Deleted state machine")
            do {
                try request.continuation.resume(returning: stateMachineHandle)
            } catch {
                request.continuation.resume(
                    throwing: StateMachineError.error(error.localizedDescription)
                )
            }
        }
    }

    nonisolated func onStateMachineSettled(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            RiveLog.trace(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Settled state machine")
            settledContinuations[stateMachineHandle]?.values.forEach { $0.yield(()) }
        }
    }

    nonisolated func onViewModelInstanceReceived(
        _ stateMachineHandle: UInt64,
        requestID: UInt64,
        viewModelInstanceHandle: UInt64
    ) {
        Task { @MainActor in
            guard let request = requests.removeValue(forKey: requestID) else {
                return
            }

            finishImmediateRequest(requestID)
            RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Received view model instance (\(viewModelInstanceHandle))")
            do {
                try request.continuation.resume(returning: viewModelInstanceHandle)
            } catch {
                request.continuation.resume(throwing: StateMachineError.error(error.localizedDescription))
            }
        }
    }

    nonisolated func onSemanticsDiffReceived(_ stateMachineHandle: UInt64, requestID: UInt64, diff: SemanticsDiff) {
        let sendableDiff = UncheckedSendable(value: diff)
        Task { @MainActor in
            RiveLog.trace(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Received semantics diff")
            semanticsDiffContinuations[stateMachineHandle]?.values.forEach { $0.yield(sendableDiff.value) }
        }
    }

    nonisolated func onHasFocusNodesReceived(_ stateMachineHandle: UInt64, requestID: UInt64, hasFocusNodes: Bool) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = requests.removeValue(forKey: requestID) else {
                #if TESTING
                onFocusResponseDiscarded?(requestID)
                #endif
                return
            }
            do {
                try request.continuation.resume(returning: hasFocusNodes)
            } catch {
                request.continuation.resume(
                    throwing: StateMachineError.error(error.localizedDescription)
                )
            }
        }
    }

    nonisolated func onFocusStateReceived(
        _ stateMachineHandle: UInt64,
        requestID: UInt64,
        focusState: CommandQueueFocusState
    ) {
        let focusState = StateMachine.FocusState(
            hasFocus: focusState.hasFocus,
            expectsKeyboardInput: focusState.expectsKeyboardInput
        )
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = requests.removeValue(forKey: requestID) else {
                #if TESTING
                onFocusResponseDiscarded?(requestID)
                #endif
                return
            }
            do {
                try request.continuation.resume(returning: focusState)
            } catch {
                request.continuation.resume(
                    throwing: StateMachineError.error(error.localizedDescription)
                )
            }
        }
    }
}

extension StateMachineService {
    /// Container for all dependencies required by the state machine service.
    struct Dependencies {
        /// The command queue used to send state machine-related commands to the C++ runtime.
        /// All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
        let messageGate: CommandQueueMessageGate

        init(commandQueue: CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}
