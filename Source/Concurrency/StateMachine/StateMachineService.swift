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
/// Handles state machine creation, advancement, deletion, and view model binding. All operations
/// are fire-and-forget (no listener callbacks). All command queue operations must be performed
/// on the main thread (either marked `@MainActor` or dispatched to the main queue).
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class StateMachineService: NSObject, StateMachineListener {
    private let dependencies: Dependencies
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]
    private var settledContinuations: [UInt64: [UUID: AsyncStream<Void>.Continuation]] = [:]
    
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
    private func withCancellableContinuation(
        cancelledError: Error,
        operation: @escaping (UInt64) -> Void
    ) async throws -> UInt64 {
        try Task.checkCancellation()
        let requestID = dependencies.commandQueue.nextRequestID
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                continuations[requestID] = continuation
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
    func hasActiveListeners() -> Bool {
        return !settledContinuations.isEmpty
    }

    /// Deletes a state machine via the command queue.
    ///
    /// The continuation is resumed when `onStateMachineDeleted` is called.
    @MainActor
    func deleteStateMachine(_ stateMachine: StateMachine.StateMachineHandle) async throws -> StateMachine.StateMachineHandle {
        RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachine)) Deleting state machine")
        return try await withCancellableContinuation(cancelledError: StateMachineError.cancelled) { requestID in
            self.dependencies.commandQueue.deleteStateMachine(stateMachine, requestID: requestID)
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

    nonisolated func onStateMachineError(_ stateMachineHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.error(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Operation failed: \(message)")
            continuation.resume(throwing: StateMachineError.error(message))
        }
    }

    nonisolated func onStateMachineDeleted(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.debug(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Deleted state machine")
            continuation.resume(returning: stateMachineHandle)
        }
    }

    nonisolated func onStateMachineSettled(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            RiveLog.trace(tag: .stateMachine, "\(Self.context(stateMachineHandle)) Settled state machine")
            settledContinuations[stateMachineHandle]?.values.forEach { $0.yield(()) }
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

