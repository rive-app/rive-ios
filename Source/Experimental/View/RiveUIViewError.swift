//
//  RiveUIViewError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

@_spi(RiveExperimental)
public enum RiveUIViewError: LocalizedError {
    case renderer(String)
    case noDrawable
    case noDevice
    case noRenderer

    public var errorDescription: String? {
        switch self {
        case .renderer(let message):
            return "Renderer error: \(message)"
        case .noDrawable:
            return "Could not retrieve drawable for drawing"
        case .noDevice:
            return "No available device for drawing"
        case .noRenderer:
            return "No available renderer for drawing"
        }
    }
}
