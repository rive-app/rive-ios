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
/// on the main thread (either marked `@MainActor` or dispatched to the main queue)
@MainActor
class StateMachineService: NSObject, StateMachineListener {
    private let dependencies: Dependencies
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]
    private var settledContinuations: [UInt64: [UUID: AsyncStream<Void>.Continuation]] = [:]

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
    }

    /// Creates a state machine from an artboard.
    ///
    /// Delegates to the command queue. Returns immediately with the state machine handle.
    /// No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - name: The name of the state machine to create. If `nil`, the default state machine is created.
    ///   - artboard: The handle of the artboard containing the state machine.
    /// - Returns: A handle that uniquely identifies the created state machine.
    @MainActor
    func createStateMachine(name: String? = nil, from artboard: Artboard.ArtboardHandle) -> StateMachine.StateMachineHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        if let name = name {
            return dependencies.commandQueue.createStateMachineNamed(name, fromArtboard: artboard, observer: self, requestID: requestID)
        } else {
            return dependencies.commandQueue.createDefaultStateMachine(fromArtboard: artboard, observer: self, requestID: requestID)
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

    /// Deletes a state machine via the command queue.
    ///
    /// The continuation is resumed when `onStateMachineDeleted` is called.
    @MainActor
    func deleteStateMachine(_ stateMachine: StateMachine.StateMachineHandle) async throws -> StateMachine.StateMachineHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.deleteStateMachine(stateMachine, requestID: requestID)
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
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.bindViewModelInstance(stateMachine, toViewModelInstance: viewModelInstance, requestID: requestID)
    }

    nonisolated func onStateMachineError(_ stateMachineHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(throwing: StateMachineServiceError.error(message))
        }
    }

    nonisolated func onStateMachineDeleted(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(returning: stateMachineHandle)
        }
    }

    nonisolated func onStateMachineSettled(_ stateMachineHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            settledContinuations[stateMachineHandle]?.values.forEach { $0.yield(()) }
        }
    }
}

private enum StateMachineServiceError: LocalizedError {
    case error(String)

    var errorDescription: String? {
        switch self {
        case .error(let message):
            return message
        }
    }
}

extension StateMachineService {
    /// Container for all dependencies required by the state machine service.
    struct Dependencies {
        /// The command queue used to send state machine-related commands to the C++ runtime.
        /// All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}

