//
//  FontError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur when decoding fonts.
///
/// These errors are thrown when font decoding fails in the C++ runtime and
/// `FontService.onFontError` is called.
@_spi(RiveExperimental)
public enum FontError: LocalizedError {
    case failedDecoding(String)
    
    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode font: \(message)"
        }
    }
}
