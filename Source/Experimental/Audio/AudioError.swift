//
//  AudioError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Errors that can occur when decoding audio.
///
/// These errors are thrown when audio decoding fails in the C++ runtime and
/// `AudioService.onAudioSourceError` is called.
@_spi(RiveExperimental)
public enum AudioError: LocalizedError {
    case failedDecoding(String)
    
    public var errorDescription: String? {
        switch self {
        case .failedDecoding(let message):
            return "Failed to decode audio: \(message)"
        }
    }
}
