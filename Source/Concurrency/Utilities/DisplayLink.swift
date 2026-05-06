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

    private let tick: Tick

    // Weak to avoid a retain cycle: CADisplayLink strongly retains its target
    // (this DefaultDisplayLink instance), so holding it strongly back would
    // create a cycle that prevents deallocation. The run loop owns the
    // CADisplayLink while it is active.
    private weak var displayLink: CADisplayLink?

    var isPaused: Bool {
        get { displayLink?.isPaused ?? true }
        set { displayLink?.isPaused = newValue }
    }

    // CADisplayLink.timestamp is 0 before its first callback. A layout-
    // triggered draw (via drawableSizeWillChange) can call draw(in:) before
    // the first tick, so fall back to CACurrentMediaTime() to avoid a zero
    // timestamp that would produce a massive delta on the next real frame.
    var timestamp: TimeInterval {
        let ts = displayLink?.timestamp ?? 0
        return ts > 0 ? ts : CACurrentMediaTime()
    }

    var frameRate: FrameRate {
        didSet {
            guard let displayLink else { return }
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
        self.tick = tick
        self.frameRate = .default

        #if !os(macOS) || RIVE_MAC_CATALYST
        let displayLink: CADisplayLink
        #if !os(visionOS)
        if let link = host.window?.windowScene?.screen.displayLink(withTarget: self, selector: #selector(_tick)) {
            RiveLog.debug(tag: .view, "[RiveUIView] Creating display link from host")
            displayLink = link
        } else {
            RiveLog.debug(tag: .view, "[RiveUIView] Creating display link fallback")
            displayLink = CADisplayLink(target: self, selector: #selector(_tick))
        }
        #else
        RiveLog.debug(tag: .view, "[RiveUIView] Creating display link")
        displayLink = CADisplayLink(target: self, selector: #selector(_tick))
        #endif
        #else
        RiveLog.debug(tag: .view, "[RiveUIView] Creating display link")
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

        displayLink.add(to: .main, forMode: .common)
        RiveLog.debug(tag: .view, "[RiveUIView] Registered display link with main run loop")
    }

    func invalidate() {
        RiveLog.debug(tag: .view, "[RiveUIView] Invalidating display link")
        displayLink?.invalidate()
    }

    @objc private func _tick() {
        tick()
    }
}
