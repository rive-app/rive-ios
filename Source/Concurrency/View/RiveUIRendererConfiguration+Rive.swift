//
//  RiveUIRendererConfiguration+Rive.swift
//  RiveRuntime
//
//  Created by Cursor Assistant on 4/6/26.
//

import Foundation

private struct RiveUIRendererConfigurationScaleProvider: ScaleProvider {
    let nativeScale: CGFloat?
    let displayScale: CGFloat
}

public extension RiveUIRendererConfiguration {
    /// Builds a renderer configuration from a `Rive` instance,
    /// resolving fit, alignment, and scale factor internally.
    @MainActor
    init(
        rive: Rive,
        drawableSize: CGSize,
        nativeScale: CGFloat? = nil,
        displayScale: CGFloat = 1
    ) {
        let scaleProvider = RiveUIRendererConfigurationScaleProvider(
            nativeScale: nativeScale,
            displayScale: displayScale
        )
        let fitBridge = rive.fit.bridged(from: scaleProvider)
        self.init(
            artboardHandle: rive.artboard.artboardHandle,
            stateMachineHandle: rive.stateMachine.stateMachineHandle,
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            size: drawableSize,
            pixelFormat: MTLRiveColorPixelFormat(),
            layoutScale: fitBridge.scaleFactor,
            color: rive.backgroundColor.argbValue
        )
    }
}
