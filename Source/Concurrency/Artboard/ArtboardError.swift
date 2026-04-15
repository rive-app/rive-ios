//
//  ArtboardError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

public enum ArtboardError: LocalizedError {
    case invalidStateMachine(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidStateMachine(let message):
            return "State machine not found: \(message)"
        }
    }
}
