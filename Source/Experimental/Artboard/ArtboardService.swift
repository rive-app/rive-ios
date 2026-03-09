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
@MainActor
class ArtboardService: NSObject, ArtboardListener {
    let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when command queue functions are called and resumed when
    /// listener callbacks are invoked. Access must be on the main thread.
    @MainActor
    private var continuations: [UInt64: Any] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Creates an artboard from a file.
    ///
    /// Delegates to the command queue. Returns immediately with the artboard handle.
    /// No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - name: The name of the artboard to create. If `nil`, the default artboard is created.
    ///   - file: The file handle containing the Rive file data.
    /// - Returns: A handle that uniquely identifies the created artboard.
    @MainActor
    func createArtboard(name: String? = nil, from file: File.FileHandle) -> Artboard.ArtboardHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        if let name = name {
            return dependencies.commandQueue.createArtboardNamed(name, fromFile: file, observer: self, requestID: requestID)
        } else {
            return dependencies.commandQueue.createDefaultArtboard(fromFile: file, observer: self, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.requestStateMachineNames(artboard, requestID: requestID)
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.requestDefaultViewModelInfo(artboard, fromFile: file, requestID: requestID)
        }
    }

    /// Sets the size of an artboard.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func setSize(of artboard: Artboard.ArtboardHandle, size: CGSize, scale: Float = 1) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.setArtboardSize(artboard, width: Float(size.width), height: Float(size.height), scale: scale, requestID: requestID)
    }

    /// Resets the size of an artboard.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func resetSize(of artboard: Artboard.ArtboardHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.resetArtboardSize(artboard, requestID: requestID)
    }

    /// Called when state machine names are listed.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the state machine names.
    nonisolated func onStateMachineNamesListed(_ artboardHandle: UInt64, names: [String], requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations[requestID] as? CheckedContinuation<[String], any Error> else { return }
            continuation.resume(returning: names)
            continuations[requestID] = nil
        }
    }

    /// Called when default view model information is received.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the view model name and instance name.
    nonisolated func onDefaultViewModelInfoReceived(_ artboardHandle: UInt64, requestID: UInt64, viewModelName: String, instanceName: String) {
        Task { @MainActor in
            guard let continuation = continuations[requestID] as? CheckedContinuation<(viewModelName: String, instanceName: String), any Error> else { return }
            continuation.resume(returning: (viewModelName: viewModelName, instanceName: instanceName))
            continuations[requestID] = nil
        }
    }

    /// Called when an artboard error occurs.
    ///
    /// Listener callback invoked by the command server. Currently does nothing; error handling
    /// could be extended if needed.
    nonisolated func onArtboardError(_ artboardHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            // For now, we don't have error continuations in the simplified version
            // This could be extended if needed for specific error handling
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
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.deleteArtboard(artboard, requestID: requestID)
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
            guard let continuation = continuations[requestID] as? CheckedContinuation<UInt64, any Error> else { return }
            continuation.resume(returning: artboardHandle)
            continuations[requestID] = nil
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
    }
}
