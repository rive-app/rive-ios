//
//  Audio.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a decoded audio source that can be used as a global asset.
///
/// Audio instances are created by decoding audio data and can be registered as global assets
/// with a worker, allowing them to be provided dynamically at runtime.
///
/// Lifetime: Audio instances are guaranteed to exist while registered as a global asset with a worker.
/// When not used as a global asset, you must maintain a strong reference to the instance to keep it alive.
@_spi(RiveExperimental)
public class Audio: Equatable {
    /// The underlying type for the audio handle identifier.
    ///
    /// Handle to an audio source in the C++ runtime. Obtained from the command queue
    /// when audio is decoded via `AudioService.decodeAudio`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `Audio` instance
    /// is deallocated via `AudioService.deleteAudio`.
    typealias AudioHandle = UInt64

    let handle: AudioHandle
    private let dependencies: Dependencies

    /// Creates an audio source by decoding the provided audio data.
    ///
    /// - Parameters:
    ///   - data: The audio data to decode
    ///   - dependencies: The dependencies required for audio operations
    /// - Throws: `AudioError.failedDecoding` if the audio data cannot be decoded
    @MainActor
    convenience init(data: Data, dependencies: Dependencies) async throws {
        let handle = try await dependencies.audioService.decodeAudio(from: data)
        self.init(handle: handle, dependencies: dependencies)
    }

    @MainActor
    init(handle: AudioHandle, dependencies: Dependencies) {
        self.handle = handle
        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.audioService
        let handle = self.handle
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteAudio(handle) else { return }
            service.deleteAudioListener(deletedHandle)
        }
    }

    /// Compares two Audio instances for equality.
    ///
    /// Two audio instances are considered equal if they reference the same underlying
    /// audio handle. This means they represent the same audio asset in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side audio instance.
    ///   - rhs: The right-hand side audio instance.
    /// - Returns: `true` if both artboards reference the same underlying artboard handle.
    public static func ==(lhs: Audio, rhs: Audio) -> Bool {
        return lhs.handle == rhs.handle
    }
}

extension Audio {
    /// Container for all dependencies required by an Audio instance.
    struct Dependencies {
        /// Provides audio-level services via command queue interactions.
        /// Implements `AudioListener` to receive callbacks from the command server.
        let audioService: AudioService
    }
}
