//
//  RiveUIViewError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

public enum RiveUIViewError: LocalizedError {
    case renderer(String)
    case noDrawable
    case noDevice
    case noRenderer
    case failedToLoad(Error)

    public var errorDescription: String? {
        switch self {
        case .renderer(let message):
            return "Error rendering: \(message)"
        case .noDrawable:
            return "Could not retrieve drawable for drawing"
        case .noDevice:
            return "No available device for drawing"
        case .noRenderer:
            return "No available renderer for drawing"
        case .failedToLoad(let error):
            return "Failed to load: \(error.localizedDescription)"
        }
    }
}
