//
//  ImageService.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages image decoding operations and coordinates with the command queue.
///
/// Implements `RenderImageListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
@MainActor
class ImageService: NSObject, RenderImageListener {
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when `decodeImage` is called and resumed when
    /// `onRenderImageDecoded` or `onRenderImageError` is called. Access must be on the main thread.
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Decodes image data into an image handle.
    ///
    /// The continuation is resumed when `onRenderImageDecoded` or `onRenderImageError` is called.
    ///
    /// - Parameter data: The image data to decode
    /// - Returns: An image handle that can be used to reference the decoded image
    /// - Throws: `ImageError.failedDecoding` if the image data cannot be decoded
    func decodeImage(from data: Data) async throws -> Image.ImageHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.decodeImage(data, listener: self, requestID: requestID)
        }
    }

    /// Deletes an image via the command queue.
    ///
    /// The continuation is resumed when `onRenderImageDeleted` is called.
    ///
    /// - Parameter renderImage: The image handle to delete
    /// - Returns: The image handle that was deleted
    @MainActor
    func deleteImage(_ renderImage: Image.ImageHandle) async throws -> Image.ImageHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.deleteImage(renderImage, requestID: requestID)
        }
    }

    /// Deletes an image listener via the command queue.
    ///
    /// - Parameter renderImage: The image handle whose listener should be removed
    @MainActor
    func deleteImageListener(_ renderImage: Image.ImageHandle) {
        dependencies.commandQueue.deleteImageListener(renderImage)
    }

    /// Called when image decoding completes successfully.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the image handle.
    nonisolated func onRenderImageDecoded(_ renderImageHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(returning: renderImageHandle)
        }
    }

    /// Called when image decoding encounters an error.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with an `ImageError`.
    nonisolated func onRenderImageError(_ renderImageHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(throwing: ImageError.failedDecoding(message))
        }
    }

    /// Called when an image is deleted.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the image handle.
    nonisolated func onRenderImageDeleted(_ renderImageHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(returning: renderImageHandle)
        }
    }
}

extension ImageService {
    /// Container for all dependencies required by the image service.
    struct Dependencies {
        /// The command queue used to send image-related commands to the C++ runtime.
        /// The service registers itself as a `RenderImageListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}
