//
//  OffMainRenderLoop.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

public extension RiveUIView {
    enum Experimental {
        /// Advances and draws `RiveUIView` from a dedicated render thread with its own
        /// display link (iOS 15+), so animations keep their frame rate while the main
        /// thread is busy. Read when a view is created.
        ///
        /// Events, semantics, settle detection, and input stay on the main thread
        /// and may lag while it is blocked.
        nonisolated(unsafe) public static var offMainRendering = false
    }

    /// Number of frames this view has submitted for presentation. Diagnostic only.
    var _presentedFrameCount: Int {
        presentedFrames.value
    }
}

final class FrameCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock { count += 1 }
    }
}

enum OffMainRenderThread {
    private static let key = "app.rive.offMainRenderThread"

    static var isCurrent: Bool {
        Thread.current.threadDictionary[key] != nil
    }

    static func markCurrent() {
        Thread.current.threadDictionary[key] = true
    }
}

/// Per-frame inputs that the main thread publishes for the render thread.
final class OffMainRenderState: @unchecked Sendable {
    struct Frame {
        var renderer: (any RiveUIRendererProtocol)?
        // POC isolation bypass: a main-actor command queue read on the render thread.
        // Only `_RiveCommandQueueAdvanceStateMachineFromAnyThread` and the renderer's
        // draw submission touch it there.
        var commandQueue: (any CommandQueueProtocol)?
        var artboardHandle: UInt64 = 0
        var stateMachineHandle: UInt64 = 0
        var fit: RiveConfigurationFit = .contain
        var alignment: RiveConfigurationAlignment = .center
        var layoutScale: CGFloat = 1
        var color: UInt32 = 0
        var isAdvancing = false
        var isOnscreen = false
        var redrawGeneration: UInt64 = 0
    }

    private let lock = NSLock()
    private var frame = Frame()

    var snapshot: Frame {
        lock.withLock { frame }
    }

    /// Returns whether the render thread has new work to pick up.
    @discardableResult
    func update(_ body: (inout Frame) -> Void) -> Bool {
        lock.withLock {
            let old = frame
            body(&frame)
            return (frame.isAdvancing && !old.isAdvancing) || frame.redrawGeneration != old.redrawGeneration
        }
    }
}

#if !os(macOS) || RIVE_MAC_CATALYST
/// Advances and draws one `RiveUIView` from a dedicated thread with its own `CADisplayLink`.
///
/// `CAMetalDisplayLink` was tried first; on the iOS 26 simulator it delivered about 50
/// updates per second at a 60 Hz target, while this link and `nextDrawable()` hold 60.
@available(iOS 15, tvOS 15, macCatalyst 15, *)
final class OffMainRenderLoop: NSObject, @unchecked Sendable {
    let state: OffMainRenderState
    private let presentedFrames: FrameCounter
    private let layer: CAMetalLayer
    private let started = DispatchSemaphore(value: 0)
    private var runLoop: CFRunLoop?

    // Render-thread only.
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var lastDrawnGeneration: UInt64?
    private var hasDrawn = false

    init(layer: CAMetalLayer, state: OffMainRenderState, presentedFrames: FrameCounter) {
        self.layer = layer
        self.state = state
        self.presentedFrames = presentedFrames
    }

    func start(frameRate: FrameRate) {
        let thread = Thread { [self] in run(frameRate: frameRate) }
        thread.name = "app.rive.render"
        thread.qualityOfService = .userInteractive
        thread.start()
        started.wait()
    }

    func stop() {
        perform {
            self.displayLink?.invalidate()
            self.displayLink = nil
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    func wake() {
        perform { self.displayLink?.isPaused = false }
    }

    func setFrameRate(_ frameRate: FrameRate) {
        perform { self.apply(frameRate) }
    }

    private func perform(_ block: @escaping () -> Void) {
        guard let runLoop else { return }
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue, block)
        CFRunLoopWakeUp(runLoop)
    }

    private func run(frameRate: FrameRate) {
        OffMainRenderThread.markCurrent()
        // CADisplayLink retains its target; stop() invalidates it to break the cycle.
        let displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        self.displayLink = displayLink
        apply(frameRate)
        displayLink.add(to: .current, forMode: .default)
        runLoop = CFRunLoopGetCurrent()
        started.signal()
        CFRunLoopRun()
    }

    private func apply(_ frameRate: FrameRate) {
        guard let displayLink else { return }
        switch frameRate {
        case .default:
            break
        case .fps(let fps):
            displayLink.preferredFrameRateRange = CAFrameRateRange(
                minimum: Float(fps),
                maximum: Float(fps),
                preferred: Float(fps)
            )
        case .range(let minimum, let maximum, let preferred):
            displayLink.preferredFrameRateRange = CAFrameRateRange(
                minimum: minimum,
                maximum: maximum,
                preferred: preferred
            )
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        let frame = state.snapshot
        guard let renderer = frame.renderer,
              let commandQueue = frame.commandQueue,
              frame.stateMachineHandle != 0
        else { return }

        let needsRedraw = frame.redrawGeneration != lastDrawnGeneration
        guard frame.isAdvancing || needsRedraw else {
            lastTimestamp = nil
            link.isPaused = true
            return
        }

        let now = link.targetTimestamp
        if frame.isAdvancing || !hasDrawn {
            let delta = lastTimestamp.map { max(0, now - $0) } ?? 0
            lastTimestamp = frame.isAdvancing ? now : nil
            _RiveCommandQueueAdvanceStateMachineFromAnyThread(commandQueue, frame.stateMachineHandle, delta)
        }
        lastDrawnGeneration = frame.redrawGeneration

        guard frame.isOnscreen || !hasDrawn else { return }
        guard let drawable = layer.nextDrawable() else { return }

        let texture = drawable.texture
        let configuration = RiveUIRendererConfiguration(
            artboardHandle: frame.artboardHandle,
            stateMachineHandle: frame.stateMachineHandle,
            fit: frame.fit,
            alignment: frame.alignment,
            size: CGSize(width: texture.width, height: texture.height),
            pixelFormat: texture.pixelFormat,
            layoutScale: frame.layoutScale,
            color: frame.color
        )
        renderer.draw(
            configuration,
            to: texture,
            from: texture.device,
            onDraw: { [presentedFrames] commandBuffer in
                commandBuffer.present(drawable)
                presentedFrames.increment()
            },
            onSkipped: nil,
            onError: { error in
                RiveLog.error(tag: .view, error: error, "[RiveUIView] Off-main draw failed")
            }
        )
        hasDrawn = true
    }
}
#endif
