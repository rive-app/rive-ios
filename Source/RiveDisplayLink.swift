//
//  RiveDisplayLink.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

protocol RiveDisplayLink {
    var isPaused: Bool { get set }
    var targetTimestamp: TimeInterval? { get }

    func set(preferredFramesPerSecond: Int) -> Void

    @available(iOS 15, macOS 14, tvOS 15, visionOS 1, *)
    func set(preferredFrameRateRange: CAFrameRateRange) -> Void

    func start()
    func stop()
}

#if !os(macOS)
class RiveCADisplayLink: RiveDisplayLink {
    typealias Tick = () -> Void

    private lazy var displayLink: CADisplayLink = {
        return CADisplayLink(target: self, selector: #selector(_tick))
    }()

    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }

    var targetTimestamp: TimeInterval? {
        displayLink.targetTimestamp
    }

    private let tick: Tick
    private var isActive = false

    init(tick: @escaping () -> Void) {
        self.tick = tick
    }

    deinit {
        displayLink.invalidate()
    }

    func set(preferredFramesPerSecond fps: Int) {
        if #available(iOS 15, tvOS 15, visionOS 1, *) {
            let range = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
            displayLink.preferredFrameRateRange = range
        } else {
            displayLink.preferredFramesPerSecond = fps
        }
    }

    @available(iOS 15, tvOS 15, visionOS 1, *)
    func set(preferredFrameRateRange range: CAFrameRateRange) {
        displayLink.preferredFrameRateRange = range
    }

    func start() {
        guard isActive == false else { return }
        displayLink.add(to: .main, forMode: .common)
        isActive = true
    }

    func stop() {
        guard isActive == true else { return }
        displayLink.invalidate()
        isActive = false
    }

    @objc private func _tick() {
        tick()
    }
}
#else
@available(macOS 14, *)
class RiveCADisplayLink: RiveDisplayLink {
    typealias Tick = () -> Void

    private let view: NSView

    private lazy var displayLink: CADisplayLink = {
        return view.displayLink(target: self, selector: #selector(_tick))
    }()

    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }

    var targetTimestamp: TimeInterval? {
        displayLink.targetTimestamp
    }

    private let tick: Tick
    private var isActive = false

    init(view: NSView, tick: @escaping Tick) {
        self.view = view
        self.tick = tick
    }

    deinit {
        displayLink.invalidate()
    }

    func set(preferredFramesPerSecond fps: Int) {
        let range = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
        displayLink.preferredFrameRateRange = range
    }

    func set(preferredFrameRateRange range: CAFrameRateRange) {
        displayLink.preferredFrameRateRange = range
    }

    func start() {
        guard isActive == false else { return }
        displayLink.add(to: .main, forMode: .common)
        isActive = true
    }

    func stop() {
        guard isActive == true else { return }
        displayLink.invalidate()
        isActive = false
    }

    @objc private func _tick() {
        tick()
    }
}

class RiveCVDisplaySync: RiveDisplayLink {
    typealias Tick = () -> Void
    
    private let tick: Tick
    
    private var displayLink: CVDisplayLink?

    var isPaused: Bool = false

    let targetTimestamp: TimeInterval? = nil

    init(tick: @escaping Tick) {
        self.tick = tick
    }

    func set(preferredFramesPerSecond: Int) { }

    func set(preferredFrameRateRange: CAFrameRateRange) { }

    func start() {
        guard displayLink == nil else { return }
        
        let result = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard result == kCVReturnSuccess, let displayLink else { return }

        CVDisplayLinkSetOutputHandler(displayLink) { _, _, _, _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.tick()
            }
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(displayLink)
    }

    func stop() {
        guard let displayLink else { return }
        CVDisplayLinkStop(displayLink)
        self.displayLink = nil
    }
}
#endif
