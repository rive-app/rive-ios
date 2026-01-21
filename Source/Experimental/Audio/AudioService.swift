//
//  AudioService.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages audio decoding operations and coordinates with the command queue.
///
/// Implements `AudioListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
@MainActor
class AudioService: NSObject, AudioListener {
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when `decodeAudio` is called and resumed when
    /// `onAudioSourceDecoded` or `onAudioSourceError` is called. Access must be on the main thread.
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Decodes audio data into an audio handle.
    ///
    /// The continuation is resumed when `onAudioSourceDecoded` or `onAudioSourceError` is called.
    ///
    /// - Parameter data: The audio data to decode
    /// - Returns: An audio handle that can be used to reference the decoded audio
    /// - Throws: `AudioError.failedDecoding` if the audio data cannot be decoded
    @MainActor
    func decodeAudio(from data: Data) async throws -> Audio.AudioHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.decodeAudio(data, listener: self, requestID: requestID)
        }
    }

    /// Deletes an audio source via the command queue.
    ///
    /// After deletion, the audio handle becomes invalid. This operation is irreversible.
    /// The `onAudioSourceDeleted` callback is invoked when the deletion completes, but no
    /// continuation handling is required for this fire-and-forget operation.
    @MainActor
    func deleteAudio(_ audioHandle: Audio.AudioHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.deleteAudio(audioHandle, requestID: requestID)
    }

    /// Called when audio decoding completes successfully.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the audio handle.
    nonisolated func onAudioSourceDecoded(_ audioHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(returning: audioHandle)
        }
    }

    /// Called when audio decoding encounters an error.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with an `AudioError`.
    nonisolated func onAudioSourceError(_ audioHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(throwing: AudioError.failedDecoding(message))
        }
    }

    /// Called when an audio source is deleted.
    ///
    /// Listener callback invoked by the command server. Audio deletions are fire-and-forget
    /// operations that don't require continuation handling.
    nonisolated func onAudioSourceDeleted(_ audioHandle: UInt64, requestID: UInt64) {

    }
}

extension AudioService {
    /// Container for all dependencies required by the audio service.
    struct Dependencies {
        /// The command queue used to send audio-related commands to the C++ runtime.
        /// The service registers itself as an `AudioListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}

