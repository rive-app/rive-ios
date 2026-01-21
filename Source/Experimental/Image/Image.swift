//
//  Image.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a decoded image that can be used as a global asset or assigned to view model properties.
///
/// Image instances are created by decoding image data (e.g., PNG, JPEG, WebP) and can be registered
/// as global assets with a worker, allowing them to be provided dynamically at runtime.
///
/// Lifetime: Image instances are guaranteed to exist while registered as a global asset with a worker.
/// When not used as a global asset, you must maintain a strong reference to the instance to keep it alive.
@_spi(RiveExperimental)
public class Image: Equatable {
    /// The underlying type for the image handle identifier.
    ///
    /// Handle to an image in the C++ runtime. Obtained from the command queue
    /// when an image is decoded via `ImageService.decodeImage`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `Image` instance
    /// is deallocated via `ImageService.deleteImage`.
    typealias ImageHandle = UInt64

    let handle: ImageHandle
    private let dependencies: Dependencies

    /// Creates an image by decoding the provided image data.
    ///
    /// - Parameters:
    ///   - data: The image data to decode (e.g., PNG, JPEG, WebP data)
    ///   - dependencies: The dependencies required for image operations
    /// - Throws: `ImageError.failedDecoding` if the image data cannot be decoded
    @MainActor
    convenience init(data: Data, dependencies: Dependencies) async throws {
        let handle = try await dependencies.imageService.decodeImage(from: data)
        self.init(handle: handle, dependencies: dependencies)
    }

    @MainActor
    init(handle: ImageHandle, dependencies: Dependencies) {
        self.handle = handle
        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.imageService
        let handle = self.handle
        Task { @MainActor in
            service.deleteImage(handle)
        }
    }

    /// Compares two Image instances for equality.
    ///
    /// Two image instances are considered equal if they reference the same underlying
    /// image handle. This means they represent the same image asset in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side image instance.
    ///   - rhs: The right-hand side image instance.
    /// - Returns: `true` if both artboards reference the same underlying artboard handle.
    public static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.handle == rhs.handle
    }
}

extension Image {
    /// Container for all dependencies required by an Image instance.
    struct Dependencies {
        /// Provides image-level services via command queue interactions.
        /// Implements `RenderImageListener` to receive callbacks from the command server.
        let imageService: ImageService
    }
}
