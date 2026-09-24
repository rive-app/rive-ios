//
//  BlobError.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur during blob operations.
///
/// `failedDecoding` is reported when blob decoding fails in the C++ runtime and
/// `BlobService.onBlobError` is called. `cancelled` is reported when a pending
/// blob decoding or deletion operation is cancelled.
public enum BlobError: LocalizedError {
    case failedDecoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode blob: \(message)"
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
