//
//  ImageError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur during image operations.
///
/// `failedDecoding` is reported when image decoding fails in the C++ runtime and
/// `ImageService.onRenderImageError` is called. `cancelled` is reported when a pending
/// image decoding or deletion operation is cancelled.
public enum ImageError: LocalizedError {
    case failedDecoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode image: \(message)"
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
