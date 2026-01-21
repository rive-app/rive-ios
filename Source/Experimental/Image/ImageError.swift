//
//  ImageError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur when decoding images.
///
/// These errors are thrown when image decoding fails in the C++ runtime and
/// `ImageService.onRenderImageError` is called.
@_spi(RiveExperimental)
public enum ImageError: LocalizedError {
    case failedDecoding(String)
    
    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode image: \(message)"
        }
    }
}
