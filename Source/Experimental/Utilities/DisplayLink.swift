//
//  DisplayLink.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/17/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// A small abstraction over platform display link implementations.
///
/// `DisplayLink` is used by `RiveUIView` to drive rendering ticks while keeping
/// the caller decoupled from platform-specific frame-rate APIs and availability checks.
@MainActor
protocol DisplayLink: AnyObject {
    /// Controls whether the display link is active and ticking.
    var isPaused: Bool { get set }
    /// Timestamp associated with the current display link tick.
    var timestamp: TimeInterval { get }
    /// Requested frame-rate policy for this display link.
    var frameRate: FrameRate { get set }
    /// Stops the display link and releases resources.
    func invalidate()
}

@MainActor
@available(macOS 14, *)
final class DefaultDisplayLink: DisplayLink {
    #if os(macOS) && !RIVE_MAC_CATALYST
    typealias Host = NSView
    #else
    typealias Host = UIView
    #endif
    typealias Tick = () -> Void

    private let host: Host
    private let tick: Tick

    private var displayLink: CADisplayLink!

    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }

    var timestamp: TimeInterval {
        return displayLink.timestamp
    }

    var frameRate: FrameRate {
        didSet {
            switch frameRate {
            case .default:
                // Restore the link's initial cadence values captured at initialization.
                #if os(macOS)
                guard let range = defaultPreferredFrameRateRange else {
                    return
                }
                displayLink.preferredFrameRateRange = CAFrameRateRange(
                    minimum: range.0,
                    maximum: range.1,
                    preferred: range.2
                )
                #else
                if #available(iOS 15, tvOS 15, *) {
                    guard let range = defaultPreferredFrameRateRange else {
                        return
                    }
                    displayLink.preferredFrameRateRange = CAFrameRateRange(
                        minimum: range.0,
                        maximum: range.1,
                        preferred: range.2
                    )
                } else {
                    displayLink.preferredFramesPerSecond = defaultPreferredFramesPerSecond
                }
                #endif
            case .fps(let fps):
                // Use range APIs when available, otherwise use the range's maximum value as the preferred fps.
                if #available(iOS 15, tvOS 15, macOS 14, *) {
                    displayLink.preferredFrameRateRange = CAFrameRateRange(
                        minimum: Float(fps),
                        maximum: Float(fps),
                        preferred: Float(fps)
                    )
                } else {
                    #if !os(macOS)
                    displayLink.preferredFramesPerSecond = fps
                    #endif
                }
            case .range(let minimum, let maximum, let preferred):
                // Older platforms do not support ranges; fall back to an explicit FPS.
                if #available(iOS 15, tvOS 15, macOS 14, *) {
                    displayLink.preferredFrameRateRange = CAFrameRateRange(
                        minimum: minimum,
                        maximum: maximum,
                        preferred: preferred
                    )
                } else {
                    #if !os(macOS)
                    displayLink.preferredFramesPerSecond = Int(maximum)
                    #endif
                }
            }
        }
    }

    #if !os(macOS)
    private var defaultPreferredFramesPerSecond: Int!
    #endif
    private var defaultPreferredFrameRateRange: (Float, Float, Float?)!

    init(host: Host, tick: @escaping Tick) {
        defer {
            self.displayLink.add(to: .main, forMode: .common)
        }

        self.host = host
        self.tick = tick
        self.frameRate = .default

        #if !os(macOS) || RIVE_MAC_CATALYST
        let displayLink: CADisplayLink
        #if !os(visionOS)
        if let link = host.window?.windowScene?.screen.displayLink(withTarget: self, selector: #selector(_tick)) {
            displayLink = link
        } else {
            displayLink = CADisplayLink(target: self, selector: #selector(_tick))
        }
        #else
        displayLink = CADisplayLink(target: self, selector: #selector(_tick))
        #endif
        #else
        var displayLink = host.displayLink(target: self, selector: #selector(_tick))
        #endif

        // Capture initial values once so `.default` has deterministic behavior and
        // does not depend on undocumented reset semantics.
        #if !os(macOS)
        defaultPreferredFramesPerSecond = displayLink.preferredFramesPerSecond
        #endif
        if #available(iOS 15, tvOS 15, *) {
            let range = displayLink.preferredFrameRateRange
            defaultPreferredFrameRateRange = (range.minimum, range.maximum, range.preferred)
        }

        self.displayLink = displayLink
        // We don't want to "tick" until the display link is set to unpaused,
        // which is done, for example, in RiveUIView when Rive.isPaused is used / updated
        self.isPaused = true
    }

    func invalidate() {
        displayLink.invalidate()
    }

    @objc private func _tick() {
        tick()
    }
}
