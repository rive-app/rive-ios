//
//  ViewModelEnum.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/10/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A struct that represents an enum definition in a view model.
///
/// Enums define named sets of string values that can be used as property types in view models.
/// Each enum has a name and a list of possible string values.
@_spi(RiveExperimental)
public struct ViewModelEnum: Sendable, Equatable {
    /// The name of the enum.
    public let name: String
    /// The list of possible string values for this enum.
    public let values: [String]

    init(name: String, values: [String]) {
        self.name = name
        self.values = values
    }
    
    /// Creates a ViewModelEnum from a dictionary.
    /// - Parameter dictionary: Dictionary containing "name" and "values" keys
    /// - Throws: An error if the dictionary is missing required keys or has invalid values
    init(from dictionary: [String: Any]) throws {
        guard let nameValue = dictionary["name"] as? String else {
            throw ViewModelEnumError.missingName
        }
        guard let valuesArray = dictionary["values"] as? [String] else {
            throw ViewModelEnumError.missingValues
        }
        
        self.name = nameValue
        self.values = valuesArray
    }
}

/// Errors that can occur when creating a ViewModelEnum from a dictionary.
///
/// These errors are thrown when parsing view model enum definitions from dictionaries
/// returned by the command queue (via `FileService.getViewModelEnums`).
enum ViewModelEnumError: LocalizedError {
    case missingName
    case missingValues
    
    var errorDescription: String? {
        switch self {
        case .missingName:
            return "Enum is missing a name"
        case .missingValues:
            return "Enum is missing values"
        }
    }
}
