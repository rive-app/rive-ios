//
//  RiveUIArtboardService.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages artboard operations and coordinates with the command queue.
///
/// Implements `ArtboardListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class ArtboardService: NSObject, ArtboardListener {
    let dependencies: Dependencies

    private static func context(_ artboard: Artboard.ArtboardHandle) -> String {
        "[Artboard (\(artboard))]"
    }

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when command queue functions are called and resumed when
    /// listener callbacks are invoked. Access must be on the main thread.
    @MainActor
    private var continuations: [UInt64: AnyContinuation] = [:]

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
    private func withCancellableContinuation<T>(
        cancelledError: Error,
        operation: @escaping (UInt64) -> Void
    ) async throws -> T {
        try Task.checkCancellation()
        let requestID = dependencies.commandQueue.nextRequestID
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                continuations[requestID] = AnyContinuation(continuation)
                beginImmediateRequest(requestID)
                operation(requestID)
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let continuation = self.continuations.removeValue(forKey: requestID) {
                    self.finishImmediateRequest(requestID)
                    try? continuation.resume(with: .failure(cancelledError))
                }
            }
        }
    }

    /// Instantiates a state machine from an artboard asynchronously.
    ///
    /// The continuation is resumed when `onStateMachineInstantiated` is called, or fails
    /// via `onArtboardError` if the server could not instantiate the state machine.
    ///
    /// - Parameters:
    ///   - name: The name of the state machine to instantiate. If `nil`, the default state machine is instantiated.
    ///   - artboardHandle: The handle of the artboard the state machine belongs to.
    ///   - observer: The observer to register for subsequent state-machine-level callbacks.
    /// - Returns: The handle of the instantiated state machine.
    /// - Throws: `ArtboardError.invalidStateMachine` if the server reports an error.
    @MainActor
    func instantiateStateMachine(name: String?, artboardHandle: Artboard.ArtboardHandle, observer: StateMachineListener) async throws -> StateMachine.StateMachineHandle {
        try await withCancellableContinuation(cancelledError: ArtboardError.cancelled) { requestID in
            let commandQueue = self.dependencies.commandQueue
            if let name {
                _ = commandQueue.createStateMachineNamed(name, fromArtboard: artboardHandle, observer: observer, requestID: requestID)
            } else {
                _ = commandQueue.createDefaultStateMachine(fromArtboard: artboardHandle, observer: observer, requestID: requestID)
            }
        }
    }

    /// Retrieves the names of all state machines available on an artboard.
    ///
    /// The continuation is resumed when `onStateMachineNamesListed` is called.
    ///
    /// - Parameter artboard: The handle of the artboard to query.
    /// - Returns: An array of state machine names available on the artboard.
    /// - Throws: `ArtboardError` if the request fails
    @MainActor
    func getStateMachineNames(from artboard: Artboard.ArtboardHandle) async throws -> [String] {
        RiveLog.debug(tag: .artboard, "\(Self.context(artboard)) Requesting state machine names")
        return try await withCancellableContinuation(cancelledError: ArtboardError.cancelled) { requestID in
            self.dependencies.commandQueue.requestStateMachineNames(artboard, requestID: requestID)
        }
    }

    /// Retrieves the default view model information for an artboard.
    ///
    /// The continuation is resumed when `onDefaultViewModelInfoReceived` is called.
    ///
    /// - Parameters:
    ///   - artboard: The handle of the artboard to query.
    ///   - file: The file handle containing the artboard.
    /// - Returns: A tuple containing the view model name and instance name.
    /// - Throws: `ArtboardError` if the request fails
    @MainActor
    func getDefaultViewModelInfo(from artboard: Artboard.ArtboardHandle, file: File.FileHandle) async throws -> (viewModelName: String, instanceName: String) {
        RiveLog.debug(tag: .artboard, "\(Self.context(artboard)) Requesting default view model info")
        return try await withCancellableContinuation(cancelledError: ArtboardError.cancelled) { requestID in
            self.dependencies.commandQueue.requestDefaultViewModelInfo(artboard, fromFile: file, requestID: requestID)
        }
    }

    /// Sets the size of an artboard.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setSize(of artboard: Artboard.ArtboardHandle, size: CGSize, scale: Float = 1) {
        RiveLog.debug(tag: .artboard, "\(Self.context(artboard)) Setting size to \(Int(size.width))x\(Int(size.height)) scale=\(scale)")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setArtboardSize(artboard, width: Float(size.width), height: Float(size.height), scale: scale, requestID: requestID)
    }

    /// Resets the size of an artboard.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func resetSize(of artboard: Artboard.ArtboardHandle) {
        RiveLog.debug(tag: .artboard, "\(Self.context(artboard)) Resetting size")
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.resetArtboardSize(artboard, requestID: requestID)
    }

    /// Called when state machine names are listed.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the state machine names.
    nonisolated func onStateMachineNamesListed(_ artboardHandle: UInt64, names: [String], requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .artboard, "\(Self.context(artboardHandle)) Received \(names.count) state machine names")
            try continuation.resume(with: .success(names))
        }
    }

    /// Called when default view model information is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the view model name and instance name.
    nonisolated func onDefaultViewModelInfoReceived(_ artboardHandle: UInt64, requestID: UInt64, viewModelName: String, instanceName: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .artboard, "\(Self.context(artboardHandle)) Received default view model info '\(viewModelName)' / '\(instanceName)'")
            try continuation.resume(with: .success((viewModelName: viewModelName, instanceName: instanceName)))
        }
    }

    /// Called when a state machine has been successfully instantiated from an artboard.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the new state machine handle.
    nonisolated func onStateMachineInstantiated(_ artboardHandle: UInt64, requestID: UInt64, stateMachineHandle: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .artboard, "\(Self.context(artboardHandle)) Instantiated state machine (\(stateMachineHandle))")
            try continuation.resume(with: .success(stateMachineHandle))
        }
    }

    /// Called when an artboard error occurs.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the pending continuation with an `ArtboardError.invalidStateMachine` error when a
    /// state machine instantiation fails.
    nonisolated func onArtboardError(_ artboardHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.error(tag: .artboard, "\(Self.context(artboardHandle)) Operation failed: \(message)")
            try continuation.resume(with: .failure(ArtboardError.invalidStateMachine(message)))
        }
    }

    /// Deletes an artboard via the command queue.
    ///
    /// The continuation is resumed when `onArtboardDeleted` is called.
    ///
    /// - Parameter artboard: The artboard handle to delete
    /// - Returns: The artboard handle that was deleted
    @MainActor
    func deleteArtboard(_ artboard: Artboard.ArtboardHandle) async throws -> Artboard.ArtboardHandle {
        RiveLog.debug(tag: .artboard, "\(Self.context(artboard)) Deleting artboard")
        return try await withCancellableContinuation(cancelledError: ArtboardError.cancelled) { requestID in
            self.dependencies.commandQueue.deleteArtboard(artboard, requestID: requestID)
        }
    }

    /// Deletes an artboard listener via the command queue.
    ///
    /// - Parameter artboard: The artboard handle whose listener should be removed
    @MainActor
    func deleteArtboardListener(_ artboard: Artboard.ArtboardHandle) {
        dependencies.commandQueue.deleteArtboardListener(artboard)
    }

    /// Called when an artboard deletion operation completes.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the artboard handle.
    nonisolated func onArtboardDeleted(_ artboardHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .artboard, "\(Self.context(artboardHandle)) Deleted artboard")
            try continuation.resume(with: .success(artboardHandle))
        }
    }
}

extension ArtboardService {
    /// Container for all dependencies required by the artboard service.
    struct Dependencies {
        /// The command queue used to send artboard-related commands to the C++ runtime.
        /// The service registers itself as an `ArtboardListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
        let messageGate: CommandQueueMessageGate

        init(commandQueue: CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}
