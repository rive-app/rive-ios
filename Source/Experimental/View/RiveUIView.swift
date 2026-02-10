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
import Combine
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

/// A UIView subclass that renders Rive animations using Metal.
///
/// RiveUIView provides a UIKit view that can display Rive animations with automatic rendering,
/// state machine advancement, and touch input handling. It uses Metal for high-performance
/// rendering and integrates with SwiftUI through the `view()` method.
@_spi(RiveExperimental)
public class RiveUIView: NativeView, MTKViewDelegate, ScaleProvider {
    var rive: Rive? {
        didSet {
            riveCancellables.removeAll()
            if let rive {
                renderer = Renderer(
                    commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue,
                    renderContext: rive.file.worker.dependencies.workerService.dependencies.renderContext
                )
                inputHandler = InputHandler(
                    dependencies: .init(
                        commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue
                    )
                )
                rive
                    .fitDidChange
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] fit in
                        guard let self else { return }
                        if case .layout = fit {
                            rive.artboard.setSize(CGSize(width: bounds.width, height: bounds.height))
                        } else {
                            rive.artboard.resetSize()
                        }
                    }.store(in: &riveCancellables)
            } else {
                renderer = nil
                inputHandler = nil
            }
            mtkView?.isPaused = rive == nil
        }
    }

    private var mtkView: MTKView?

    private var lastTimestamp: TimeInterval?

    private var renderer: Renderer?

    private var inputHandler: InputHandler?

    weak var delegate: RiveUIViewDelegate?

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

    private var riveCancellables = Set<AnyCancellable>()

    /// Creates a new RiveUIView that asynchronously loads a Rive configuration.
    ///
    /// This initializer creates a view and then asynchronously loads the Rive configuration
    /// from the provided closure. The view will start rendering once the configuration is loaded.
    ///
    /// - Parameter rive: An async closure that returns a `Rive` configuration
    @MainActor
    public convenience init(rive: @MainActor @escaping () async throws -> Rive, delegate: RiveUIViewDelegate? = nil) {
        self.init(rive: nil, delegate: delegate)

        Task { @MainActor [weak self] in
            self?.rive = try await rive()
        }
    }

    /// Creates a new RiveUIView with an optional Rive configuration.
    ///
    /// If a configuration is provided, the view will immediately start rendering.
    /// If `nil` is provided, the view will be created but won't render until a configuration is set.
    ///
    /// - Parameter rive: An optional `Rive` configuration to display
    @MainActor
    public init(rive: Rive?, delegate: RiveUIViewDelegate? = nil) {
        defer {
            self.rive = rive
        }

        self.delegate = delegate
        super.init(frame: .zero)

        Task { @MainActor in
            await setup()
        }
    }

    /// Initializer for Interface Builder (not supported).
    ///
    /// This initializer is not implemented and will always fatal error.
    public required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not yet implemented")
    }

    @MainActor
    private func setup() async {
        guard mtkView == nil, let device = await MetalDevice.shared.defaultDevice() else { return }
        let mtkView = MTKView(frame: bounds, device: device)
        mtkView.delegate = self
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
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
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    /// Renders the Rive animation to the Metal view.
    ///
    /// This method is called by MetalKit to render each frame. It advances the state machine
    /// based on elapsed time and renders the artboard using the current fit and alignment settings.
    ///
    /// - Parameter view: The Metal view to render into
    public func draw(in view: MTKView) {
        guard let rive else {
            return
        }

        if let lastTimestamp {
            let now = CACurrentMediaTime()
            rive.stateMachine.advance(by: now - lastTimestamp)
            self.lastTimestamp = now
        } else {
            rive.stateMachine.advance(by: 0)
            lastTimestamp = CACurrentMediaTime()
        }

        if isOnscreen() {
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

                let fitBridge = rive.fit.bridged(from: self)
                let configuration = RendererConfiguration(
                    artboardHandle: rive.artboard.artboardHandle,
                    stateMachineHandle: rive.stateMachine.stateMachineHandle,
                    fit: fitBridge.fit,
                    alignment: fitBridge.alignment,
                    size: view.drawableSize,
                    pixelFormat: MTLRiveColorPixelFormat(),
                    layoutScale: fitBridge.scaleFactor,
                    color: rive.backgroundColor.argbValue
                )

                renderer.draw(configuration, to: currentDrawable.texture, from: device) { commandBuffer in
                    commandBuffer.present(currentDrawable)
                    commandBuffer.commit()
                } onError: { [weak self] error in
                    guard let self else { return }
                    self.delegate?.view(self, didReceiveError: RiveUIViewError.renderer(error.localizedDescription))
                }
            }
        }
    }

    /// Returns a SwiftUI view representation of this RiveUIView.
    ///
    /// This method allows the RiveUIView to be used within SwiftUI views using UIViewRepresentable.
    ///
    /// - Returns: A SwiftUI view that wraps this RiveUIView
    @ViewBuilder
    public func view() -> some View {
        ConfigurationViewRepresentable(view: self)
    }

#if canImport(UIKit) || RIVE_MAC_CATALYST
    /// Handles touch events when touches begin.
    ///
    /// This method converts touch events into pointer down events for the state machine.
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handlePointerEvent(from: touches, with: { .pointerDown($0) })
    }

    /// Handles touch events when touches end.
    ///
    /// This method converts touch events into pointer up events for the state machine.
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handlePointerEvent(from: touches, with: { .pointerUp($0) })
    }

    /// Handles touch events when touches move.
    ///
    /// This method converts touch events into pointer move events for the state machine.
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handlePointerEvent(from: touches, with: { .pointerMove($0) })
    }

    /// Handles touch events when touches are cancelled.
    ///
    /// This method converts touch events into pointer exit events for the state machine.
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handlePointerEvent(from: touches, with: { .pointerExit($0) })
    }

    private func handlePointerEvent(
        from touches: Set<UITouch>,
        with inputType: (PointerEvent) -> Input
    ) {
        guard let rive,
              let inputHandler,
              let touch = touches.first
        else { return }

        let fitBridge = rive.fit.bridged(from: self)

        let event = PointerEvent(
            position: touch.location(in: self),
            bounds: bounds.size,
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            scaleFactor: Float(fitBridge.scaleFactor)
        )
        inputHandler.handle(inputType(event), in: rive.stateMachine)
    }
#else
    public override func mouseDown(with event: NSEvent) {
        handlePointerEvent(from: event, with: { .pointerDown($0) })
    }

    public override func mouseUp(with event: NSEvent) {
        handlePointerEvent(from: event, with: { .pointerUp($0) })
    }

    public override func mouseMoved(with event: NSEvent) {
        handlePointerEvent(from: event, with: { .pointerMove($0) })
    }

    public override func mouseExited(with event: NSEvent) {
        handlePointerEvent(from: event, with: { .pointerExit($0) })
    }

    private func handlePointerEvent(
        from event: NSEvent,
        with inputType: (PointerEvent) -> Input
    ) {
        guard let rive,
              let inputHandler
        else { return }

        let fitBridge = rive.fit.bridged(from: self)
        let position = convert(event.locationInWindow, to: self)

        let event = PointerEvent(
            position: position,
            bounds: bounds.size,
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            scaleFactor: Float(fitBridge.scaleFactor)
        )
        inputHandler.handle(inputType(event), in: rive.stateMachine)
    }
#endif
}

/// A SwiftUI view representable that wraps a `RiveUIView` for use in SwiftUI.
///
/// This struct enables `RiveUIView` to be used within SwiftUI views. It wraps
/// the provided view and returns it in `makeUIView`, and syncs the view's current
/// state in `updateUIView` whenever SwiftUI re-renders.
struct ConfigurationViewRepresentable: NativeViewRepresentable {
    private let view: RiveUIView

    init(view: RiveUIView) {
        self.view = view
    }

#if canImport(UIKit) || RIVE_MAC_CATALYST
    func makeUIView(context: Context) -> RiveUIView {
        return view
    }

    func updateUIView(_ uiView: RiveUIView, context: Context) {
        // Read current values from the view to ensure we're always in sync
        uiView.rive = view.rive
        uiView.delegate = view.delegate
    }
#else
    func makeNSView(context: Context) -> RiveUIView {
        return RiveUIView(rive: view.rive, delegate: view.delegate)
    }

    func updateNSView(_ nsView: RiveUIView, context: Context) {
        // Read current values from the view to ensure we're always in sync
        nsView.rive = view.rive
        nsView.delegate = view.delegate
    }
#endif
}
