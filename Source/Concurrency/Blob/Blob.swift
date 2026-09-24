//
//  Blob.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// A binary asset that can be assigned to a view model blob property.
///
/// Create instances with `Worker.decodeBlob(from:)`. A view model instance retains
/// blobs assigned to its properties until they are replaced, cleared, or the instance
/// is released. Keep a strong reference to any blob that is not assigned to a property.
public final class Blob: Equatable {
    /// The underlying type for the blob handle identifier.
    ///
    /// Handle to a blob in the C++ runtime. Obtained from the command queue
    /// when a blob is decoded via `BlobService.decodeBlob`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `Blob` instance
    /// is deallocated via `BlobService.deleteBlob`.
    typealias BlobHandle = UInt64

    let handle: BlobHandle
    private let dependencies: Dependencies

    /// Creates a blob by decoding the provided blob data.
    ///
    /// - Parameters:
    ///   - data: The blob data to decode (arbitrary binary data)
    ///   - dependencies: The dependencies required for blob operations
    /// - Throws: `BlobError.failedDecoding` if the blob data cannot be decoded
    @MainActor
    convenience init(data: Data, dependencies: Dependencies) async throws {
        RiveLog.debug(tag: .blob, "[Blob] Initializing blob from data (\(data.count) bytes)")
        let handle = try await dependencies.blobService.decodeBlob(from: data)
        RiveLog.debug(tag: .blob, "[Blob (\(handle))] Initialized blob")
        self.init(handle: handle, dependencies: dependencies)
    }


    @MainActor
    init(handle: BlobHandle, dependencies: Dependencies) {
        self.handle = handle
        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.blobService
        let handle = self.handle
        RiveLog.debug(tag: .blob, "[Blob (\(handle))] Deinitializing blob; scheduling cleanup")
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteBlob(handle) else { return }
            service.deleteBlobListener(deletedHandle)
        }
    }

    /// Compares two Blob instances for equality.
    ///
    /// Two blob instances are considered equal if they reference the same underlying
    /// blob handle. This means they represent the same blob asset in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side blob instance.
    ///   - rhs: The right-hand side blob instance.
    /// - Returns: `true` if both blobs reference the same underlying blob handle.
    public static func ==(lhs: Blob, rhs: Blob) -> Bool {
        return lhs.handle == rhs.handle
    }
}

extension Blob {
    /// Container for all dependencies required by a Blob instance.
    struct Dependencies {
        /// Provides blob-level services via command queue interactions.
        /// Implements `BlobListener` to receive callbacks from the command server.
        let blobService: BlobService
    }
}
