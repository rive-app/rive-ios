//
//  FileError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

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
            return "File not found: \(message)"
        case .invalidData(let message):
            return "Invalid file data: \(message)"
        case .missingData(let message):
            return "No data available: \(message)"
        case .invalidFile(let message):
            return "Failed to load file: \(message)"
        case .invalidArtboard(let message):
            return "Artboard not found: \(message)"
        case .invalidViewModel(let message):
            return "View model not found: \(message)"
        case .invalidViewModelInstance(let message):
            return "View model instance not found: \(message)"
        }
    }
}
