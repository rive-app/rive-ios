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
import os

#if canImport(UIKit) || RIVE_MAC_CATALYST
import UIKit
public typealias NativeView = UIView
public typealias NativeViewRepresentable = UIViewRepresentable
#else
import AppKit
public typealias NativeView = NSView
public typealias NativeViewRepresentable = NSViewRepresentable
#endif

@_spi(RiveExperimental)
public protocol RiveUIViewDelegate: AnyObject {
    func view(_ view: RiveUIView, didReceiveError: RiveUIViewError)
}

/// A UIView / NSView subclass that renders Rive animations using Metal.
///
/// RiveUIView provides a native view that can display Rive animations with automatic rendering,
/// state machine advancement, and touch / pointer input handling. It uses Metal for high-performance
/// rendering.
@_spi(RiveExperimental)
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

    private var renderer: Renderer?

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

    // Called when isPaused is set, since we need to maintain
    // state independently from the display link and controller
    private var _isPaused: Bool = true {
        didSet {
            let newValue = _isPaused
            if newValue {
                controller?.resetTiming()
            }
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

    // Track the paused state independently of `self` being a DisplayLink (i.e macOS < 14)
    // This is so that we can update any new display links to the correct starting state
    // Satisfies the DisplayLink protocol
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

        Task { @MainActor [weak self] in
            guard let self else { return }
            await setupTask?.value
            do {
                self.rive = try await rive()
            } catch {
                delegate?.view(self, didReceiveError: .failedToLoad(error))
            }
            self.isPaused = isPaused
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
            self.isPaused = isPaused
        }
    }

    /// Initializer for Interface Builder (not supported).
    ///
    /// This initializer is not implemented and will always fatal error.
    public required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not yet implemented")
    }

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
        guard mtkView == nil, let device = await MetalDevice.shared.defaultDevice()?.value else { return }
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
    }

    private func setupRive() {
        if let rive {
            renderer = Renderer(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue,
                renderContext: rive.file.worker.dependencies.workerService.dependencies.renderContext
            )

            controller = RiveController(
                rive: rive,
                boundsProvider: { [weak self] in
                    self?.bounds.size ?? .zero
                }
            )

            if isPaused {
                controller?.resetTiming()
            }

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
            renderer = nil
            controller = nil
        }

        updateDisplayLink()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

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
        let configuration = controller.advance(
            now: now,
            isPaused: isPaused,
            isOnscreen: isOnscreen(),
            drawableSize: view.drawableSize,
            scaleProvider: self
        )

        guard let configuration else {
            return
        }

        autoreleasepool {
            guard let device = view.device else {
                delegate?.view(self, didReceiveError: .noDevice)
                return
            }

            guard let currentDrawable = view.currentDrawable else {
                delegate?.view(self, didReceiveError: .noDrawable)
                return
            }

            guard let renderer else {
                delegate?.view(self, didReceiveError: .noRenderer)
                return
            }

            renderer.draw(configuration, to: currentDrawable.texture, from: device) { commandBuffer in
                commandBuffer.present(currentDrawable)
                commandBuffer.commit()
            } onError: { [weak self] error in
                guard let self else { return }
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
              let controller
        else { return }

        for touch in touches {
            let fitBridge = rive.fit.bridged(from: self)

            let event = PointerEvent(
                id: AnyHashable(touch),
                position: touch.location(in: self),
                bounds: bounds.size,
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

    private func handlePointerEvent(
        from event: NSEvent,
        with inputType: (PointerEvent) -> Input
    ) {
        guard let rive,
              let controller
        else { return }

        let fitBridge = rive.fit.bridged(from: self)
        let position = convert(event.locationInWindow, to: self)

        let event = PointerEvent(
            id: AnyHashable(event.buttonNumber),
            position: position,
            bounds: bounds.size,
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
            displayLink = nil
            return
        }

        // Prefer a real CADisplayLink-backed implementation when available.
        // On older macOS, fall back to this view as the display-link adapter.
        let displayLink: DisplayLink
        // All versions of !macOS or Catalyst have a CADisplayLink-backed display link.
        #if !os(macOS) || RIVE_MAC_CATALYST
        displayLink = DefaultDisplayLink(host: self) { [weak self] in
            self?.tick()
        }
        #else
        // On macOS 14+, use the DefaultDisplayLink implementation (as CADisplayLink is available).
        if #available(macOS 14, *) {
            displayLink = DefaultDisplayLink(host: self) { [weak self] in
                self?.tick()
            }
        } else {
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
