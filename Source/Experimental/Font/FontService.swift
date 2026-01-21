//
//  FontService.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages font decoding operations and coordinates with the command queue.
///
/// Implements `FontListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
@MainActor
class FontService: NSObject, FontListener {
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to continuations for async operations.
    ///
    /// Continuations are stored when `decodeFont` is called and resumed when
    /// `onFontDecoded` or `onFontError` is called. Access must be on the main thread.
    private var continuations: [UInt64: CheckedContinuation<UInt64, Error>] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Decodes font data into a font handle.
    ///
    /// The continuation is resumed when `onFontDecoded` or `onFontError` is called.
    ///
    /// - Parameter data: The font data to decode
    /// - Returns: A font handle that can be used to reference the decoded font
    /// - Throws: `FontError.failedDecoding` if the font data cannot be decoded
    func decodeFont(from data: Data) async throws -> Font.FontHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = continuation
            commandQueue.decodeFont(data, listener: self, requestID: requestID)
        }
    }

    /// Deletes a font via the command queue.
    ///
    /// After deletion, the font handle becomes invalid. This operation is irreversible.
    /// The `onFontDeleted` callback is invoked when the deletion completes, but no
    /// continuation handling is required for this fire-and-forget operation.
    @MainActor
    func deleteFont(_ fontHandle: Font.FontHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.deleteFont(fontHandle, requestID: requestID)
    }

    /// Called when font decoding completes successfully.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with the font handle.
    nonisolated func onFontDecoded(_ fontHandle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(returning: fontHandle)
        }
    }

    /// Called when font decoding encounters an error.
    ///
    /// Listener callback invoked by the command server. Resumes the continuation with a `FontError`.
    nonisolated func onFontError(_ fontHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else {
                return
            }

            continuation.resume(throwing: FontError.failedDecoding(message))
        }
    }

    /// Called when a font is deleted.
    ///
    /// Listener callback invoked by the command server. Font deletions are fire-and-forget
    /// operations that don't require continuation handling.
    nonisolated func onFontDeleted(_ fontHandle: UInt64, requestID: UInt64) {

    }
}

extension FontService {
    /// Container for all dependencies required by the font service.
    struct Dependencies {
        /// The command queue used to send font-related commands to the C++ runtime.
        /// The service registers itself as a `FontListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}

