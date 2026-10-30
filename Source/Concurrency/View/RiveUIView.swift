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
    /// Called on the main actor when the view encounters an error.
    @MainActor
    func view(_ view: RiveUIView, didReceiveError: RiveUIViewError)
}

/// A UIView / NSView subclass that renders Rive animations using Metal.
///
/// RiveUIView provides a native view that can display Rive animations with automatic rendering,
/// state machine advancement, and touch / pointer input handling. It uses Metal for high-performance
/// rendering.
public class RiveUIView: NativeView, MTKViewDelegate, ScaleProvider, DisplayLink, RiveControllerDelegate {
    public enum Constants {
        public enum Defaults {
            public static let isPaused = false
            public static let frameRate: FrameRate = .default
            #if !os(macOS) || RIVE_MAC_CATALYST
            public static let semantics: Semantics = .off
            #endif
        }
    }

    public var rive: Rive? {
        didSet {
            // Treat identity changes as updates
            guard rive !== oldValue else {
                return
            }

            setupRive()
        }
    }

    class MetalView: MTKView {
        /// Uses this view's layer capacity to coordinate drawable acquisition and retirement.
        private(set) lazy var drawableCoordinator: DrawableCoordinator? = {
            guard let metalLayer = layer as? CAMetalLayer else {
                RiveLog.error(tag: .view, "[RiveUIView] Cannot coordinate drawables: expected a Metal layer")
                return nil
            }
            return DrawableCoordinator(layer: metalLayer)
        }()

        #if !os(macOS) || RIVE_MAC_CATALYST
        override func willMove(toWindow newWindow: UIWindow?) {
            #if !os(visionOS)
            if autoResizeDrawable, let screen = newWindow?.screen {
                // Avoid MetalKit's transform-dependent contentScaleFactor setter.
                layer.contentsScale = screen.nativeScale
                // Layer scale changes alone do not invalidate the drawable size.
                setNeedsLayout()
            }
            #endif
            super.willMove(toWindow: newWindow)
        }
        #else
        override func convertToBacking(_ size: NSSize) -> NSSize {
            guard autoResizeDrawable else { return super.convertToBacking(size) }
            // MetalKit uses this conversion for automatic drawable sizing. The
            // backing texture uses layer coordinates, before ancestor transforms.
            let scale = layer?.contentsScale ?? window?.backingScaleFactor ?? 1
            let localSize = convertToLayer(size)
            return NSSize(width: localSize.width * scale, height: localSize.height * scale)
        }

        override func convertFromBacking(_ size: NSSize) -> NSSize {
            guard autoResizeDrawable else { return super.convertFromBacking(size) }
            let scale = layer?.contentsScale ?? window?.backingScaleFactor ?? 1
            return convertFromLayer(NSSize(width: size.width / scale, height: size.height / scale))
        }
        #endif
    }

    private var mtkView: MTKView?
    #if os(macOS) && !RIVE_MAC_CATALYST
    private var contentsScaleObservation: NSKeyValueObservation?
    #endif
    private var renderer: (any RiveUIRendererProtocol)?
    private var pendingConfiguration: RiveUIRendererConfiguration?

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

    // MARK: RiveControllerDelegate

    var drawableSize: CGSize {
        mtkView?.drawableSize ?? .zero
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    var accessibilityContainer: AnyObject { self }

    func controller(_ controller: RiveController, didUpdateModalState isModal: Bool) -> Bool {
        let transitioned = accessibilityViewIsModal != isModal
        accessibilityViewIsModal = isModal
        return transitioned
    }
    #endif

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
                mtkView?.enableSetNeedsDisplay = newValue
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
    public var frameRate: FrameRate = Constants.Defaults.frameRate {
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

    private var _isOpaque: Bool = false

    public override var isOpaque: Bool {
        get { _isOpaque }
        set {
            _isOpaque = newValue
            #if canImport(UIKit) || RIVE_MAC_CATALYST
            mtkView?.isOpaque = newValue
            #else
            mtkView?.layer?.isOpaque = newValue
            #endif
        }
    }

    #if os(iOS) || os(visionOS) || RIVE_MAC_CATALYST
    public override var isMultipleTouchEnabled: Bool {
        didSet {
            mtkView?.isMultipleTouchEnabled = isMultipleTouchEnabled
        }
    }
    #endif

    #if !os(macOS) || RIVE_MAC_CATALYST
    private var _semantics: Semantics = Constants.Defaults.semantics {
        didSet {
            controller?.semantics = _semantics
        }
    }

    /// The VoiceOver accessibility semantics mode for this Rive view.
    public var semantics: Semantics {
        get { _semantics }
        set { _semantics = newValue }
    }

    public override var accessibilityElements: [Any]? {
        get { controller?.semanticsController.accessibilityElements ?? [] }
        set { }
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
    public convenience init(rive: @MainActor @escaping () async throws -> Rive, delegate: RiveUIViewDelegate? = nil, isPaused: Bool = Constants.Defaults.isPaused) {
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
    public init(rive: Rive?, delegate: RiveUIViewDelegate? = nil, isPaused: Bool = Constants.Defaults.isPaused) {
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
        let mtkView = MetalView(frame: bounds, device: device)
        mtkView.delegate = self
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        #if os(iOS) || os(visionOS) || RIVE_MAC_CATALYST
        mtkView.isMultipleTouchEnabled = isMultipleTouchEnabled
        #endif
        self.mtkView = mtkView
        #if os(macOS) && !RIVE_MAC_CATALYST
        contentsScaleObservation = mtkView.observe(\.layer?.contentsScale, options: [.old, .new]) { view, change in
            MainActor.assumeIsolated {
                guard view.autoResizeDrawable, change.oldValue != change.newValue else { return }
                // Layer scale changes do not invalidate MetalKit's drawable size.
                // Reapply the point size to refresh its automatic pixel sizing.
                view.setFrameSize(view.frame.size)
                if view.enableSetNeedsDisplay {
                    view.needsDisplay = true
                } else if view.isPaused {
                    // The macOS 13 display-link fallback needs an explicit frame while paused.
                    view.draw()
                }
            }
        }
        #endif
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
        mtkView.isOpaque = isOpaque
#else
        layer?.backgroundColor = NSColor.clear.cgColor
        mtkView.layer?.backgroundColor = NSColor.clear.cgColor
        mtkView.layer?.isOpaque = isOpaque
#endif

        // Capture defaults once so `.default` does not rely on undocumented resets.
        defaultFramesPerSecond = mtkView.preferredFramesPerSecond
    }

    private func setupRive() {
        pendingConfiguration = nil
        if let rive {
            RiveLog.debug(tag: .view, "[RiveUIView] Setting up Rive renderer and controller")
            renderer = rive.makeRenderer()

            controller = RiveController(rive: rive, delegate: self)
            controller?.isPaused = isPaused
            #if !os(macOS) || RIVE_MAC_CATALYST
            controller?.semantics = semantics
            #endif

            mtkView?.draw()
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
        guard let view = view as? MetalView else {
            RiveLog.error(tag: .view, "[RiveUIView] Draw failed: unexpected Metal view type")
            return
        }

        // Setup can request a draw before layout sizes the Metal view. Wait for
        // a valid drawable size without consuming the controller's first draw.
        guard view.drawableSize.width > 0, view.drawableSize.height > 0 else {
            RiveLog.trace(tag: .view, "[RiveUIView] Skipping draw: drawable size is empty")
            return
        }

        let now = displayLink?.timestamp ?? CACurrentMediaTime()
        #if TESTING
        let isOnscreenValue = isOnscreenForTesting ?? isOnscreen()
        #else
        let isOnscreenValue = isOnscreen()
        #endif
        // Prefer fresh work; only reuse a pending configuration while onscreen.
        let configuration = controller.advance(
            now: now,
            isOnscreen: isOnscreenValue,
            drawableSize: view.drawableSize,
            scaleProvider: self
        ) ?? (isOnscreenValue ? pendingConfiguration : nil)

        guard let configuration else {
            return
        }

        // Bind main-actor-side MetalKit and drawable temporaries to this
        // submission. The asynchronous command-server callback has its own
        // autorelease pool in `_RiveUIRendererCore`.
        autoreleasepool {
            guard let device = view.device else {
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing device")
                delegate?.view(self, didReceiveError: .noDevice)
                return
            }

            guard let renderer else {
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing renderer")
                delegate?.view(self, didReceiveError: .noRenderer)
                return
            }

            guard let frame = view.drawableCoordinator?.beginFrame({
                guard let drawable = view.currentDrawable else {
                    RiveLog.error(tag: .view, "[RiveUIView] Draw failed: missing drawable")
                    delegate?.view(self, didReceiveError: .noDrawable)
                    return nil
                }
                return drawable
            }) else {
                // Error handling may have replaced the graphic during acquisition.
                if self.controller === controller {
                    requestRedraw(configuration)
                }
                return
            }
            guard let currentDrawable = frame.drawable else {
                RiveLog.error(tag: .view, "[RiveUIView] Draw failed: acquired frame has no drawable")
                delegate?.view(self, didReceiveError: .noDrawable)
                return
            }

            // This submission replaces any pending redraw.
            pendingConfiguration = nil
            renderer.draw(
                configuration,
                to: currentDrawable.texture,
                from: device,
                onDraw: { commandBuffer in
                    frame.present(on: commandBuffer)
                },
                onSkipped: nil,
                onError: { [weak self] error in
                    self?.notifyDelegateOfRendererError(error)
                }
            )

        }
    }

    private nonisolated func notifyDelegateOfRendererError(_ error: Error) {
        RiveLog.error(tag: .view, error: error, "[RiveUIView] Error rendering")
        let description = error.localizedDescription
        Task { @MainActor [weak self] in
            guard let self else { return }
            delegate?.view(self, didReceiveError: .renderer(description))
        }
    }

    #if TESTING
    var isOnscreenForTesting: Bool?

    func configureDrawingForTesting(
        controller: RiveController,
        metalView: MetalView,
        renderer: any RiveUIRendererProtocol
    ) async {
        // Let normal setup finish before installing controlled drawing dependencies.
        await setupTask?.value
        mtkView?.removeFromSuperview()
        mtkView = metalView
        self.controller = controller
        self.renderer = renderer
        controller.isPaused = isPaused
    }

    nonisolated func notifyDelegateOfRendererErrorForTesting(_ error: Error) {
        notifyDelegateOfRendererError(error)
    }
    #endif

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

    public override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
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

    private func requestRedraw(_ configuration: RiveUIRendererConfiguration) {
        pendingConfiguration = configuration
        // Invalidate after MetalKit finishes the current draw. A successful
        // intervening submission clears pending work and makes this a no-op.
        DispatchQueue.main.async { [weak self] in
            if let _ = self?.pendingConfiguration {
                self?.tick()
            }
        }
    }

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
            // The pause setter selects timed updates while playing and native
            // invalidation while paused, including pending redraws.
        }
        #endif

        // Re-apply current configuration whenever the display-link instance changes.
        self.displayLink = displayLink
        displayLink.frameRate = frameRate
        displayLink.isPaused = isPaused
        if pendingConfiguration != nil {
            tick()
        }
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
    /// Coordinates drawable ownership separately from permission to submit a frame.
    ///
    /// `beginFrame` drains queued main-thread releases, then takes a permit without
    /// waiting. If no permit is available, it never calls the drawable provider.
    /// A provider returning nil immediately returns its permit.
    ///
    /// Rendering and GPU callbacks keep the frame alive. Its final owner queues
    /// `endFrame`; `drain` releases our drawable reference on main and sets
    /// `isReleased`. Presentation independently clears `isAwaitingPresentation`.
    /// These events may happen in either order; capacity returns only after both.
    /// The presentation handler captures storage, not the frame, so it cannot
    /// prevent the frame's deinit from scheduling main-thread release.
    ///
    /// Skipped frames never wait for presentation. Command-buffer errors end that
    /// wait, with late presentation callbacks ignored for permit accounting.
    /// Simulator SDKs omit presentation handlers, so they use the GPU-completion
    /// and main-thread-release path only.
    final class DrawableCoordinator: @unchecked Sendable {
        private let semaphore: DispatchSemaphore
        private let lock = NSLock()
        private var pending: [DrawableFrame.Storage] = []

        @MainActor
        init(layer: CAMetalLayer) {
            // Each slot stays occupied until both main-thread release and
            // presentation complete. Do not subtract a reserved onscreen slot:
            // presentation tracking already holds permits for pending frames.
            // A two-slot budget on a three-drawable layer caused avoidable skips
            // at 60 Hz when presentation took nearly two refresh intervals.
            // This is submission accounting, not a guarantee that Metal's next
            // drawable is immediately available (especially during resizing).
            semaphore = DispatchSemaphore(value: layer.maximumDrawableCount)
        }

        /// Drains pending releases before acquiring a drawable. Does not call
        /// the provider when the budget is exhausted; a failed provider returns
        /// its permit immediately.
        @MainActor
        func beginFrame(_ acquireDrawable: () -> CAMetalDrawable?) -> DrawableFrame? {
            drain()
            guard semaphore.wait(timeout: .now()) == .success else {
                RiveLog.debug(tag: .view, "[RiveUIView] Skipping draw: drawable budget exhausted")
                return nil
            }
            guard let drawable = acquireDrawable() else {
                semaphore.signal()
                return nil
            }
            return DrawableFrame(drawable, coordinator: self)
        }

        /// Ends the frame by queuing drawable release on main. Capacity also waits
        /// for presentation to finish.
        fileprivate func endFrame(_ storage: DrawableFrame.Storage) {
            let needsDrain = lock.withLock {
                pending.append(storage)
                return pending.count == 1
            }
            if needsDrain {
                DispatchQueue.main.async { self.drain() }
            }
        }

        fileprivate func willPresent(_ storage: DrawableFrame.Storage) {
            lock.withLock { storage.isAwaitingPresentation = true }
        }

        fileprivate func didPresent(_ storage: DrawableFrame.Storage) {
            finishPresentation(storage)
        }

        fileprivate func didFailToPresent(_ storage: DrawableFrame.Storage) {
            finishPresentation(storage)
        }

        private func finishPresentation(_ storage: DrawableFrame.Storage) {
            lock.withLock {
                // An error and a late presentation callback may both arrive.
                guard storage.isAwaitingPresentation else { return }
                storage.isAwaitingPresentation = false
                signalIfReady(storage)
            }
        }

        /// Called under the lock when either retirement or presentation completes.
        private func signalIfReady(_ storage: DrawableFrame.Storage) {
            if storage.isReleased && !storage.isAwaitingPresentation {
                semaphore.signal()
            }
        }

        /// Releases each drawable on main. Its permit also waits for presentation
        /// (or failure); skipped frames have no presentation to wait for.
        @MainActor
        func drain() {
            let retirements = lock.withLock {
                let retirements = pending
                pending.removeAll()
                return retirements
            }
            for storage in retirements {
                storage.drawable = nil
                lock.withLock {
                    // Each frame enqueues retirement exactly once, in deinit.
                    storage.isReleased = true
                    signalIfReady(storage)
                }
            }
        }
    }

    /// Keeps a drawable alive through its rendering and GPU completion callbacks,
    /// then hands it back to its coordinator for main-thread retirement.
    final class DrawableFrame: @unchecked Sendable {
        // A shared slot lets main release the drawable even while the worker
        // finishes releasing its reference to this storage.
        fileprivate final class Storage: @unchecked Sendable {
            var drawable: CAMetalDrawable?
            // Protected by the coordinator's lock.
            var isAwaitingPresentation = false
            var isReleased = false

            init(_ drawable: CAMetalDrawable) {
                self.drawable = drawable
            }
        }

        private let storage: Storage
        private let coordinator: DrawableCoordinator

        fileprivate init(_ drawable: CAMetalDrawable, coordinator: DrawableCoordinator) {
            storage = Storage(drawable)
            self.coordinator = coordinator
        }

        var drawable: CAMetalDrawable? {
            storage.drawable
        }

        /// Wires retirement and schedules presentation. The renderer owns commit.
        func present(on commandBuffer: MTLCommandBuffer) {
            guard let drawable else {
                assertionFailure("Drawable must remain alive while its callback executes")
                return
            }
            #if !targetEnvironment(simulator)
            // Simulator SDKs do not expose drawable presentation handlers.
            drawable.addPresentedHandler(presentationHandler())
            #endif
            commandBuffer.addCompletedHandler { [self] commandBuffer in
                if commandBuffer.status == .error {
                    didFailToPresent()
                }
                // Keep the frame alive through GPU completion. The renderer
                // commits the buffer after its onDraw callback returns.
                withExtendedLifetime(self) {}
            }
            commandBuffer.present(drawable)
        }

        func presentationHandler() -> MTLDrawablePresentedHandler {
            coordinator.willPresent(storage)
            // Do not capture the frame: its deinit must remain free to
            // enqueue main-thread release of storage.drawable after GPU completion.
            return { [coordinator, storage] _ in
                coordinator.didPresent(storage)
            }
        }

        func didFailToPresent() {
            coordinator.didFailToPresent(storage)
        }

        deinit {
            coordinator.endFrame(storage)
        }
    }
}
