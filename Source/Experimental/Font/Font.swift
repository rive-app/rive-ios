//
//  Font.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a decoded font that can be used as a global asset.
///
/// Font instances are created by decoding font data (e.g., TTF, OTF) and can be registered
/// as global assets with a worker, allowing them to be provided dynamically at runtime.
///
/// Lifetime: Font instances are guaranteed to exist while registered as a global asset with a worker.
/// When not used as a global asset, you must maintain a strong reference to the instance to keep it alive.
@_spi(RiveExperimental)
public class Font: Equatable {
    /// The underlying type for the font handle identifier.
    ///
    /// Handle to a font in the C++ runtime. Obtained from the command queue
    /// when a font is decoded via `FontService.decodeFont`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `Font` instance
    /// is deallocated via `FontService.deleteFont`.
    typealias FontHandle = UInt64

    let handle: FontHandle
    private let dependencies: Dependencies

    /// Creates a font by decoding the provided font data.
    ///
    /// - Parameters:
    ///   - data: The font data to decode (e.g., TTF, OTF data)
    ///   - dependencies: The dependencies required for font operations
    /// - Throws: `FontError.failedDecoding` if the font data cannot be decoded
    @MainActor
    convenience init(data: Data, dependencies: Dependencies) async throws {
        let handle = try await dependencies.fontService.decodeFont(from: data)
        self.init(handle: handle, dependencies: dependencies)
    }

    @MainActor
    init(handle: FontHandle, dependencies: Dependencies) {
        self.handle = handle
        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.fontService
        let handle = self.handle
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteFont(handle) else { return }
            service.deleteFontListener(deletedHandle)
        }
    }

    /// Compares two Font instances for equality.
    ///
    /// Two font instances are considered equal if they reference the same underlying
    /// font handle. This means they represent the same font asset in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side font instance.
    ///   - rhs: The right-hand side font instance.
    /// - Returns: `true` if both fonts reference the same underlying fonthandle.
    public static func ==(lhs: Font, rhs: Font) -> Bool {
        return lhs.handle == rhs.handle
    }
}

extension Font {
    /// Container for all dependencies required by a Font instance.
    struct Dependencies {
        /// Provides font-level services via command queue interactions.
        /// Implements `FontListener` to receive callbacks from the command server.
        let fontService: FontService
    }
}
