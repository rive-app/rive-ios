//
//  FontError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur during font operations.
///
/// `failedDecoding` is reported when font decoding fails in the C++ runtime and
/// `FontService.onFontError` is called. `cancelled` is reported when a pending
/// font decoding or deletion operation is cancelled.
public enum FontError: LocalizedError {
    case failedDecoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode font: \(message)"
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
