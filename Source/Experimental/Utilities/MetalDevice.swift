//
//  MetalDevice.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/27/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import Metal

actor MetalDevice {
    static let shared = MetalDevice()
    private var defaultDevice: UncheckedSendable<MTLDevice>?

    func defaultDevice() async -> UncheckedSendable<MTLDevice>? {
        if let defaultDevice {
            return defaultDevice
        }

        let device = await Task.detached { () -> UncheckedSendable<MTLDevice>? in
            guard let device = MTLCreateSystemDefaultDevice() else {
                return nil
            }

            return UncheckedSendable(value: device)
        }.value

        defaultDevice = device
        return device
    }
}
