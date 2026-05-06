//
//  RiveUIView.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/17/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI

#if canImport(UIKit) || RIVE_MAC_CATALYST
import UIKit
public typealias NativeView = UIView
public typealias NativeViewRepresentable = UIViewRepresentable
#else
import AppKit
public typealias NativeView = NSView
public typealias NativeViewRepresentable = NSViewRepresentable
#endif

public protocol RiveUIViewDelegate: AnyObject {
    func view(_ view: RiveUIView, didReceiveError: RiveUIViewError)
}

/// A UIView / NSView subclass that renders Rive animations using Metal.
///
/// RiveUIView provides a native view that can display Rive animations with automatic rendering,
/// state machine advancement, and touch / pointer input handling. It uses Metal for high-performance
/// rendering.
public class RiveUIView: NativeView, MTKViewDelegate, ScaleProvider, DisplayLink {
    public var rive: Rive? {
        didSet {
            // Treat identity changes as updates
            guard rive !== oldValue else {
                return
            }

            setupRive()
        }
    }

    private var mtkView: MTKView?
    /// Guards drawable acquisition to avoid blocking the main thread.
    /// `currentDrawable` blocks if all drawables are in use; the semaphore
    /// lets `draw(in:)` bail early with a non-blocking `wait(timeout: .now())`
    /// instead. Signaled via ``DrawableToken`` when the draw completes.
    private var drawableSemaphore: DispatchSemaphore?

    private var renderer: RiveUIRenderer?

    private var controller: RiveController?
    private var setupTask: Task<Void, Never>?

    // MARK: ScaleProvider
    var nativeScale: CGFloat? {
#if canImport(UIKit) || RIVE_MAC_CATALYST
    #if os(visionOS)
        return nil
    #else
        return window?.windowScene?.screen.nativeScale
    #endif
#else
        return nil
#endif
    }

    var displayScale: CGFloat {
#if canImport(UIKit) || RIVE_MAC_CATALYST
        return traitCollection.displayScale
#else
        return NSScreen.main?.backingScaleFactor ?? 1
#endif
    }

    // MARK: DisplayLink

    private var displayLink: DisplayLink? {
        didSet {
            // This cannot be called in deinit (here or in a concrete implementation), as a DisplayLink is main-actor-isolated, 
            // and deinit is nonisolated.
            oldValue?.invalidate()
        }
    }

    // Backing store for `isPaused`. Propagates changes to the controller and
    // display link so all rendering subsystems stay in sync.
    //
    // This is the source of truth for pause state. Async setup tasks must
    // never overwrite it from a captured init parameter — they should read
    // `self.isPaused` instead, so post-init mutations by the caller are
    // respected.
    private var _isPaused: Bool = true {
        didSet {
            let newValue = _isPaused
            controller?.isPaused = newValue
            #if !os(macOS) || RIVE_MAC_CATALYST
            displayLink?.isPaused = newValue
            #else
            if #unavailable(macOS 14) {
                mtkView?.isPaused = newValue
            } else {
                displayLink?.isPaused = newValue
            }
            #endif
        }
    }

    // Public accessor for `_isPaused`. Tracks pause state independently of
    // `self` acting as its own DisplayLink (macOS < 14) so that newly created
    // display links inherit the correct starting state.
    // Satisfies the DisplayLink protocol.
    public var isPaused: Bool {
        get {
            return _isPaused
        } set {
            _isPaused = newValue
        }
    }

    // Used when self.displayLink == self (i.e macOS < 14)
    var timestamp: TimeInterval {
        CACurrentMediaTime()
    }

    /// Initial `MTKView.preferredFramesPerSecond` captured during setup.
    ///
    /// Used to restore deterministic behavior when `frameRate` returns to `.default`.
    private var defaultFramesPerSecond: Int?

    // MARK: Helpers

    // MARK: Public

    // This is for implementing DisplayLink as well as the public view property
    public var frameRate: FrameRate = .default {
        didSet {
            guard frameRate != oldValue else { return }
            // Calling displayLink?.frameRate here would cause an infinite loop,
            // so if we are the display link, we want to directly modify mtkView
            // This will typically be encountered when macOS < 14
            if displayLink === self {
                // This fallback implementation only controls `MTKView` scalar FPS.
                // `DefaultDisplayLink` owns full range support where available.
                // However, we only want to modify MTKView when the display link is self
                // (i.e macOS < 14)
                switch frameRate {
                case .default:
                    // Restore the initial MTKView FPS captured in `setup()`.
                    guard let fps = defaultFramesPerSecond else {
                        return
                    }
                    mtkView?.preferredFramesPerSecond = fps
                case .fps(let fps):
                    mtkView?.preferredFramesPerSecond = fps
                case .range(_, let maximum, _):
                    // `MTKView` has no range API here, so collapse range to scalar FPS.
                    mtkView?.preferredFramesPerSecond = Int(maximum)
                }
            } else {
                // Otherwise, forward the frame rate to the display link (i.e DefaultDisplayLink)
                displayLink?.frameRate = frameRate
            }
        }
    }

    public weak var delegate: RiveUIViewDelegate?

    #if os(iOS) || os(visionOS) || RIVE_MAC_CATALYST
    public override var isMultipleTouchEnabled: Bool {
        didSet {
            mtkView?.isMultipleTouchEnabled = isMultipleTouchEnabled
        }
    }
    #endif

    // MARK: -

    /// Creates a new RiveUIView that asynchronously loads a Rive configuration.
    ///
    /// This initializer creates a view and then asynchronously loads the Rive configuration
    /// from the provided closure. The view will start rendering once the configuration is loaded.
    ///
    /// - Parameter rive: An async closure that returns a `Rive` configuration
    @MainActor
    public convenience init(rive: @MainActor @escaping () async throws -> Rive, delegate: RiveUIViewDelegate? = nil, isPaused: Bool = false) {
        self.init(rive: nil, delegate: delegate, isPaused: isPaused)
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing with async Rive loader")

        Task { @MainActor [weak self] in
            guard let self else { return }
            await setupTask?.value
            do {
                self.rive = try await rive()
                RiveLog.debug(tag: .view, "[RiveUIView] Loaded Rive configuration from async loader")
            } catch {
                RiveLog.error(tag: .view, error: error, "[RiveUIView] Failed to load Rive configuration")
                delegate?.view(self, didReceiveError: .failedToLoad(error))
            }
        }
    }

    /// Creates a new RiveUIView with an optional Rive configuration.
    ///
    /// If a configuration is provided, the view will immediately start rendering.
    /// If `nil` is provided, the view will be created but won't render until a configuration is set.
    ///
    /// - Parameter rive: An optional `Rive` configuration to display
    @MainActor
    public init(rive: Rive?, delegate: RiveUIViewDelegate? = nil, isPaused: Bool = false) {
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing view")
        #if !os(macOS) || RIVE_MAC_CATALYST
        defer { Notifications.observe() }
        #endif

        self.rive = rive
        self.delegate = delegate
        super.init(frame: .zero)

        #if os(iOS) || os(visionOS) || RIVE_MAC_CATALYST
        self.isMultipleTouchEnabled = true
        #endif

        self.isPaused = isPaused

        setupTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await setupView()
            setupRive()
        }
    }

    /// Initializer for Interface Builder (not supported).
    ///
    /// This initializer is not implemented and will always fatal error.
    public required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not yet implemented")
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    deinit {
        Notifications.unobserve()
    }
    #endif

    #if !os(macOS) || RIVE_MAC_CATALYST
    public override func didMoveToWindow() {
        // This is also called when the view is removed (before deinit), which will
        // implicitly invalidate the display link. 
        updateDisplayLink()
    }
    #else
    public override func viewDidMoveToWindow() {
        // This is also called when the view is removed (before deinit), which will
        // implicitly invalidate the display link.
        updateDisplayLink()
    }
    #endif
    
    @MainActor
    private func setupView() async {
        guard mtkView == nil else { return }
        guard let device = await MetalDevice.shared.defaultDevice()?.value else {
            RiveLog.error(tag: .view, "[RiveUIView] Failed to set up MTKView: missing Metal device")
            return
        }
        let mtkView = MTKView(frame: bounds, device: device)
        mtkView.delegate = self
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        #if os(iOS) || os(visionOS) || RIVE_MAC_CATALYST
        mtkView.isMultipleTouchEnabled = isMultipleTouchEnabled
        #endif
        self.mtkView = mtkView
        addSubview(mtkView)

        mtkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mtkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mtkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mtkView.topAnchor.constraint(equalTo: topAnchor),
            mtkView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

#if canImport(UIKit) || RIVE_MAC_CATALYST
        backgroundColor = .clear
        mtkView.backgroundColor = .clear
#else
        layer?.backgroundColor = NSColor.clear.cgColor
        mtkView.layer?.backgroundColor = NSColor.clear.cgColor
#endif

        // Capture defaults once so `.default` does not rely on undocumented resets.
        defaultFramesPerSecond = mtkView.preferredFramesPerSecond

        // Limit per-view in-flight rendering to the layer drawable budget.
        let maxDrawableCount: Int
        if let metalLayer = mtkView.layer as? CAMetalLayer {
            maxDrawableCount = metalLayer.maximumDrawableCount
        } else {
            maxDrawableCount = 1
        }
        drawableSemaphore = DispatchSemaphore(value: maxDrawableCount)
    }

    private func setupRive() {
        if let rive {
            RiveLog.debug(tag: .view, "[RiveUIView] Setting up Rive renderer and controller")
            renderer = RiveUIRenderer(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue,
                renderContext: rive.file.worker.dependencies.workerService.dependencies.renderContext
            )

            controller = RiveController(
                rive: rive,
                drawableSizeProvider: { [weak self] in
                    self?.mtkView?.drawableSize
                },
                scaleProvider: { [weak self] in
                    self
                }
            )
            controller?.isPaused = isPaused

            // If we are paused, we want to draw at least one frame
            // We'll leverage MTKView's (set)NeedsDisplay to draw once
            // and return to the previous settings. This accounts for
            // both iOS and macOS, on all OSes
            if isPaused {
                guard let mtkView else {
                    return
                }

                let currentIsPaused = mtkView.isPaused
                let currentEnableSetNeedsDisplay = mtkView.enableSetNeedsDisplay

                mtkView.isPaused = true
                mtkView.enableSetNeedsDisplay = true

                tick()

               mtkView.isPaused = currentIsPaused
               mtkView.enableSetNeedsDisplay = currentEnableSetNeedsDisplay
            }
        } else {
            RiveLog.debug(tag: .view, "[RiveUIView] Clearing Rive renderer and controller")
            renderer = nil
            controller = nil
        }

        updateDisplayLink()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Drawable size changes (window resize, backing scale factor change) do
        // not otherwise trigger a draw when the MTKView is paused + uses
        // enableSetNeedsDisplay. Request a single redraw; the controller will
        // detect the new drawableSize and emit a fresh configuration even if
        // the state machine has settled.
        #if !os(macOS) || RIVE_MAC_CATALYST
        view.setNeedsDisplay()
        #else
        view.needsDisplay = true
        #endif
    }

    /// Renders the Rive animation to the Metal view.
    ///
    /// This method is called by MetalKit to render each frame. It advances the state machine
    /// based on elapsed time and renders the artboard using the current fit and alignment settings.
    ///
    /// - Parameter view: The Metal view to render into
    public func draw(in view: MTKView) {
        guard let controller else {
            return
        }

        let now = displayLink?.timestamp ?? CACurrentMediaTime()
        let isOnscreenValue = isOnscreen()
        let configuration = controller.advance(
            now: now,
            isOnscreen: isOnscreenValue,
            drawableSize: view.drawableSize,
            scaleProvider: self
        )

        guard let configuration else {
            return
        }

        autoreleasepool {
            guard let device = view.device else {
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing device")
                delegate?.view(self, didReceiveError: .noDevice)
                return
            }

            guard let drawableSemaphore else {
                return
            }

            guard drawableSemaphore.wait(timeout: .now()) == .success else {
                return
            }

            // Token guarantees signal() for this wait(), even if the draw
            // callback is never executed (e.g. CommandServer disconnects first).
            let token = DrawableToken(drawableSemaphore)

            guard let currentDrawable = view.currentDrawable else {
                token.signal()
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing drawable")
                delegate?.view(self, didReceiveError: .noDrawable)
                return
            }

            guard let renderer else {
                token.signal()
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing renderer")
                delegate?.view(self, didReceiveError: .noRenderer)
                return
            }

            renderer.draw(configuration, to: currentDrawable.texture, from: device) { commandBuffer in
                commandBuffer.addCompletedHandler { _ in
                    token.signal()
                }
                commandBuffer.present(currentDrawable)
                commandBuffer.commit()
            } onSkipped: {
                token.signal()
            } onError: { [weak self] error in
                token.signal()
                guard let self else { return }
                RiveLog.error(tag: .view, error: error, "[RiveUIView] Error rendering")
                self.delegate?.view(self, didReceiveError: RiveUIViewError.renderer(error.localizedDescription))
            }

        }
    }

    // MARK: - DisplayLink
    func invalidate() {
        mtkView?.isPaused = true
    }

    // MARK: - Input
#if canImport(UIKit) || RIVE_MAC_CATALYST
    /// Handles touch events when touches begin.
    ///
    /// This method converts touch events into pointer down events for the state machine.
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handlePointerEvent(from: touches, with: { .pointerDown($0) })
    }

    /// Handles touch events when touches end.
    ///
    /// This method converts touch events into pointer up events for the state machine.
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handlePointerEvent(from: touches, with: { .pointerUp($0) })
    }

    /// Handles touch events when touches move.
    ///
    /// This method converts touch events into pointer move events for the state machine.
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handlePointerEvent(from: touches, with: { .pointerMove($0) })
    }

    /// Handles touch events when touches are cancelled.
    ///
    /// This method converts touch events into pointer exit events for the state machine.
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handlePointerEvent(from: touches, with: { .pointerExit($0) })
    }

    private func handlePointerEvent(
        from touches: Set<UITouch>,
        with inputType: (PointerEvent) -> Input
    ) {
        guard let rive,
              let controller,
              let mtkView
        else { return }

        let drawableSize = mtkView.drawableSize
        let scale = CGFloat(mtkView.contentScaleFactor)

        for touch in touches {
            let fitBridge = rive.fit.bridged(from: self)
            let location = touch.location(in: self)

            let event = PointerEvent(
                id: AnyHashable(touch),
                position: CGPoint(x: location.x * scale, y: location.y * scale),
                bounds: drawableSize,
                fit: fitBridge.fit,
                alignment: fitBridge.alignment,
                scaleFactor: Float(fitBridge.scaleFactor)
            )
            controller.handleInput(inputType(event))
        }
    }
#else
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        handlePointerEvent(from: event, with: { .pointerDown($0) })
    }

    public override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        handlePointerEvent(from: event, with: { .pointerUp($0) })
    }

    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        handlePointerEvent(from: event, with: { .pointerMove($0) })
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        handlePointerEvent(from: event, with: { .pointerExit($0) })
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // AppKit only delivers mouseMoved / mouseEntered / mouseExited events
        // to views that own a tracking area configured for them. `.inVisibleRect`
        // keeps the tracked rect in sync with the view's bounds automatically,
        // so we only need to install the tracking area once.
        let alreadyInstalled = trackingAreas.contains { area in
            area.owner as? RiveUIView === self
                && area.options.contains(.inVisibleRect)
        }
        guard !alreadyInstalled else { return }

        let area = NSTrackingArea(
            rect: .zero, // ignored when .inVisibleRect is set
            options: [.inVisibleRect, .mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    private func handlePointerEvent(
        from event: NSEvent,
        with inputType: (PointerEvent) -> Input
    ) {
        guard let rive,
              let controller,
              let mtkView
        else { return }

        let fitBridge = rive.fit.bridged(from: self)
        let drawableSize = mtkView.drawableSize
        let scale = mtkView.layer?.contentsScale ?? 1

        // AppKit's default NSView coordinate system is bottom-left origin,
        // but the state machine / renderer expect top-left (matching UIKit),
        // so flip Y to match the `RiveView` behavior.
        let location = convert(event.locationInWindow, from: nil)
        let position = CGPoint(
            x: location.x * scale,
            y: (bounds.height - location.y) * scale
        )

        let event = PointerEvent(
            id: AnyHashable(event.buttonNumber),
            position: position,
            bounds: drawableSize,
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            scaleFactor: Float(fitBridge.scaleFactor)
        )
        controller.handleInput(inputType(event))
    }
#endif

    // MARK: - Private

    private func updateDisplayLink() {
        guard window != nil else {
            RiveLog.debug(tag: .view, "[RiveUIView] Clearing display link; view is off-window")
            displayLink = nil
            return
        }

        // Prefer a real CADisplayLink-backed implementation when available.
        // On older macOS, fall back to this view as the display-link adapter.
        let displayLink: DisplayLink
        // All versions of !macOS or Catalyst have a CADisplayLink-backed display link.
        #if !os(macOS) || RIVE_MAC_CATALYST
        RiveLog.debug(tag: .view, "[RiveUIView] Configuring CADisplayLink-backed display link")
        displayLink = DefaultDisplayLink(host: self) { [weak self] in
            self?.tick()
        }
        #else
        // On macOS 14+, use the DefaultDisplayLink implementation (as CADisplayLink is available).
        if #available(macOS 14, *) {
            RiveLog.debug(tag: .view, "[RiveUIView] Configuring CADisplayLink-backed display link")
            displayLink = DefaultDisplayLink(host: self) { [weak self] in
                self?.tick()
            }
        } else {
            RiveLog.debug(tag: .view, "[RiveUIView] Configuring MTKView-backed display link fallback")
            // On macOS 13 or older, fall back to mtkView as the display-link adapter.
            displayLink = self
            // mtkView?.isPaused is implicitly set by displayLink.isPaused below
            // enableSetNeedsDisplay is set to false since this "display link" needs to
            // tick and draw based on mtkView's isPaused state, contrary to a CADisplayLink-backed
            // display link that controls ticking and requesting to draw (via setNeedsDisplay)
            // This overrides the setting in setup()
            mtkView?.enableSetNeedsDisplay = false
        }
        #endif

        // Re-apply current configuration whenever the display-link instance changes.
        displayLink.frameRate = frameRate
        displayLink.isPaused = isPaused
        self.displayLink = displayLink
    }

    private func tick() {
        #if !os(macOS) || RIVE_MAC_CATALYST
        mtkView?.setNeedsDisplay()
        #else
        mtkView?.needsDisplay = true
        #endif
    }

}

extension RiveUIView {
    /// A one-shot guard that ensures a `DispatchSemaphore` is signaled exactly once
    /// for each corresponding `wait()`.
    ///
    /// Created per draw cycle in `draw(in:)` after `drawableSemaphore.wait()` succeeds.
    /// The token is captured by the draw callback closures (finalize, onSkipped, onError).
    /// If the callback executes normally, `signal()` is called explicitly. If the callback
    /// is never executed — e.g. when `CommandServer` processes a `disconnect` before the
    /// draw loop runs — the closures are destroyed, the token's `deinit` fires, and the
    /// semaphore is signaled automatically, preventing a `SIGTRAP` from libdispatch's
    /// "Semaphore object deallocated while in use" assertion.
    ///
    /// See: https://github.com/rive-app/rive-ios/issues/442
    final class DrawableToken: @unchecked Sendable {
        private let semaphore: DispatchSemaphore
        private let lock = NSLock()
        private var didSignal = false

        init(_ semaphore: DispatchSemaphore) {
            self.semaphore = semaphore
        }

        /// Signals the semaphore. Safe to call multiple times — only the first call signals.
        func signal() {
            let shouldSignal = lock.withLock {
                guard !didSignal else { return false }
                didSignal = true
                return true
            }
            if shouldSignal {
                semaphore.signal()
            }
        }

        /// Signals the semaphore if `signal()` was never called explicitly.
        deinit {
            if !didSignal {
                semaphore.signal()
            }
        }
    }
}
