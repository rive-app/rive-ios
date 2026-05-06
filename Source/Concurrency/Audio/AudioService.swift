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
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class AudioService: NSObject, AudioListener {
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when `decodeAudio` is called and resumed when
    /// `onAudioSourceDecoded` or `onAudioSourceError` is called. Access must be on the main thread.
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]

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

    /// Decodes audio data into an audio handle.
    ///
    /// The continuation is resumed when `onAudioSourceDecoded` or `onAudioSourceError` is called.
    ///
    /// - Parameter data: The audio data to decode
    /// - Returns: An audio handle that can be used to reference the decoded audio
    /// - Throws: `AudioError.failedDecoding` if the audio data cannot be decoded
    @MainActor
    func decodeAudio(from data: Data) async throws -> Audio.AudioHandle {
        RiveLog.debug(tag: .audio, "[Audio] Decoding audio data (\(data.count) bytes)")
        return try await withCancellableContinuation(cancelledError: AudioError.cancelled) { requestID in
            self.dependencies.commandQueue.decodeAudio(data, listener: self, requestID: requestID)
        }
    }

    /// Deletes an audio source via the command queue.
    ///
    /// The continuation is resumed when `onAudioSourceDeleted` is called.
    ///
    /// - Parameter audioHandle: The audio handle to delete
    /// - Returns: The audio handle that was deleted
    @MainActor
    func deleteAudio(_ audioHandle: Audio.AudioHandle) async throws -> Audio.AudioHandle {
        RiveLog.debug(tag: .audio, "[Audio] Deleting audio")
        return try await withCancellableContinuation(cancelledError: AudioError.cancelled) { requestID in
            self.dependencies.commandQueue.deleteAudio(audioHandle, requestID: requestID)
        }
    }

    /// Deletes an audio listener via the command queue.
    ///
    /// - Parameter audioHandle: The audio handle whose listener should be removed
    @MainActor
    func deleteAudioListener(_ audioHandle: Audio.AudioHandle) {
        dependencies.commandQueue.deleteAudioListener(audioHandle)
    }

    /// Called when audio decoding completes successfully.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the audio handle.
    nonisolated func onAudioSourceDecoded(_ audioHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.debug(tag: .audio, "[Audio] Decoded audio")
            continuation.resume(returning: audioHandle)
        }
    }

    /// Called when audio decoding encounters an error.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with an `AudioError`.
    nonisolated func onAudioSourceError(_ audioHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.error(tag: .audio, "[Audio] Failed to decode audio: \(message)")
            continuation.resume(throwing: AudioError.failedDecoding(message))
        }
    }

    /// Called when an audio source is deleted.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the audio handle.
    nonisolated func onAudioSourceDeleted(_ audioHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.debug(tag: .audio, "[Audio] Deleted audio")
            continuation.resume(returning: audioHandle)
        }
    }
}

extension AudioService {
    /// Container for all dependencies required by the audio service.
    struct Dependencies {
        /// The command queue used to send audio-related commands to the C++ runtime.
        /// The service registers itself as an `AudioListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
        let messageGate: CommandQueueMessageGate

        init(commandQueue: CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}

