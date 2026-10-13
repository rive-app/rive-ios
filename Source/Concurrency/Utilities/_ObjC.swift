//
//  _ObjC.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/14/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

/// Objective-C-only bridge to MainActor APIs used by RiveRuntime internals.
/// Swift code should use MainActor APIs directly.
@objc(_RiveMainActor)
final class _RiveMainActor: NSObject {
    @objc static func assertIsolated(_ message: String) {
        assert({
            // Off-main rendering POC: the render thread submits draws through
            // the main-actor command queue API. See OffMainRenderLoop.
            if OffMainRenderThread.isCurrent { return true }
            MainActor.assertIsolated(message)
            return true
        }())
    }
}
