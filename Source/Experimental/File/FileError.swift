//
//  FileError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

@_spi(RiveExperimental)
public enum FileError: LocalizedError {
    case missingFile(String)
    case invalidData(String)
    case missingData(String)
    case invalidFile(String)
    case invalidArtboard(String)
    case invalidViewModel(String)
    case invalidViewModelInstance(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingFile(let message):
            return "File cannot be found: \(message)"
        case .invalidData(let message):
            return "Data cannot be loaded: \(message)"
        case .missingData(let message):
            return "Data is empty: \(message)"
        case .invalidFile(let message):
            return "File could not be loaded: \(message)"
        case .invalidArtboard(let message):
            return "Artboard does not exist: \(message)"
        case .invalidViewModel(let message):
            return "View model does not exist: \(message)"
        case .invalidViewModelInstance(let message):
            return "View model instance does not exist: \(message)"
        }
    }
}
