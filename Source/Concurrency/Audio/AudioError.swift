//
//  AudioError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur during audio operations.
///
/// `failedDecoding` is reported when audio decoding fails in the C++ runtime and
/// `AudioService.onAudioSourceError` is called. `cancelled` is reported when a pending
/// audio decoding or deletion operation is cancelled.
public enum AudioError: LocalizedError {
    case failedDecoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode audio: \(message)"
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
