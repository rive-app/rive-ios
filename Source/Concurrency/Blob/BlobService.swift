//
//  BlobService.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// A service class that manages blob decoding operations and coordinates with the command queue.
///
/// Implements `BlobListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
///
/// All continuation-based methods are wrapped with `withTaskCancellationHandler` because
/// `withCheckedThrowingContinuation` does not auto-resume on task cancellation. Without
/// explicit handling, a cancelled task leaks its continuation indefinitely.
@MainActor
final class BlobService: NSObject, BlobListener {
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when `decodeBlob` is called and resumed when
    /// `onBlobDecoded` or `onBlobError` is called. Access must be on the main thread.
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
        guard !Task.isCancelled else {
            throw cancelledError
        }
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

    /// Decodes blob data into a blob handle.
    ///
    /// The continuation is resumed when `onBlobDecoded` or `onBlobError` is called.
    ///
    /// - Parameter data: The blob data to decode
    /// - Returns: A blob handle that can be used to reference the decoded blob
    /// - Throws: `BlobError.failedDecoding` if the blob data cannot be decoded
    func decodeBlob(from data: Data) async throws -> Blob.BlobHandle {
        RiveLog.debug(tag: .blob, "[Blob] Decoding blob data (\(data.count) bytes)")
        var pendingHandle: Blob.BlobHandle?
        do {
            return try await withCancellableContinuation(cancelledError: BlobError.cancelled) { requestID in
                pendingHandle = self.dependencies.commandQueue.decodeBlob(data, listener: self, requestID: requestID)
            }
        } catch {
            if let pendingHandle {
                // Keep the service alive until deletion completes, even if the caller
                // cancelled before decoding finished. Commands execute in queue order.
                Task { @MainActor in
                    guard let deletedHandle = try? await self.deleteBlob(pendingHandle) else { return }
                    self.deleteBlobListener(deletedHandle)
                }
            }
            throw error
        }
    }


    /// Deletes a blob via the command queue.
    ///
    /// The continuation is resumed when `onBlobDeleted` is called.
    ///
    /// - Parameter blobHandle: The blob handle to delete
    /// - Returns: The blob handle that was deleted
    @MainActor
    func deleteBlob(_ blobHandle: Blob.BlobHandle) async throws -> Blob.BlobHandle {
        RiveLog.debug(tag: .blob, "[Blob] Deleting blob")
        return try await withCancellableContinuation(cancelledError: BlobError.cancelled) { requestID in
            self.dependencies.commandQueue.deleteBlob(blobHandle, requestID: requestID)
        }
    }

    /// Deletes a blob listener via the command queue.
    ///
    /// - Parameter blobHandle: The blob handle whose listener should be removed
    @MainActor
    func deleteBlobListener(_ blobHandle: Blob.BlobHandle) {
        dependencies.commandQueue.deleteBlobListener(blobHandle)
    }

    /// Called when blob decoding completes successfully.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the blob handle.
    nonisolated func onBlobDecoded(_ blobHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.debug(tag: .blob, "[Blob] Decoded blob")
            continuation.resume(returning: blobHandle)
        }
    }

    /// Called when blob decoding encounters an error.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with a `BlobError`.
    nonisolated func onBlobError(_ blobHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.error(tag: .blob, "[Blob] Failed to decode blob: \(message)")
            continuation.resume(throwing: BlobError.failedDecoding(message))
        }
    }

    /// Called when a blob is deleted.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the blob handle.
    nonisolated func onBlobDeleted(_ blobHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            RiveLog.debug(tag: .blob, "[Blob] Deleted blob")
            continuation.resume(returning: blobHandle)
        }
    }
}

extension BlobService {
    /// Container for all dependencies required by the blob service.
    struct Dependencies {
        /// The command queue used to send blob-related commands to the C++ runtime.
        /// The service registers itself as a `BlobListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
        let messageGate: CommandQueueMessageGate

        init(commandQueue: CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}
