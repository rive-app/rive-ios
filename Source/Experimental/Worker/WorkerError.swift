//
//  WorkerError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/27/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

@_spi(RiveExperimental)
public enum WorkerError: LocalizedError {
    case missingDevice

    public var errorDescription: String? {
        switch self {
        case .missingDevice:
            return "No device found for drawing"
        }
    }
}
