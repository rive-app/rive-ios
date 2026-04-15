//
//  FrameRate.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/19/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Controls how the runtime requests display cadence from its display link.
///
/// On platforms that support frame-rate ranges, `.range` can be applied directly.
/// On older platforms (`< iOS 15`, `< tvOS 15`, and `< macOS 14`), range
/// preferences are translated to a scalar FPS value, using the maximum value of the range.
public enum FrameRate: Equatable {
    /// Uses the display link's initial settings (prioritizing range, if available).
    case `default`
    /// Requests a fixed preferred frames-per-second value.
    case fps(Int)
    /// Requests a preferred frame-rate range.
    ///
    /// - Parameters:
    ///   - minimum: Lower bound of the desired frame rate.
    ///   - maximum: Upper bound of the desired frame rate.
    ///   - preferred: Optional preferred value within the range.
    case range(minimum: Float, maximum: Float, preferred: Float?)
}
