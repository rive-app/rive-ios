//
//  ViewModelProperty.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A struct that represents the metadata of a view model property.
///
/// This struct contains information about a property defined in a view model, including
/// its type, name, and optional metadata. It is used to discover the structure of view models.
@_spi(RiveExperimental)
public struct ViewModelProperty: Sendable, Equatable {
    /// The data type of the property within the view model.
    public let type: DataType
    
    /// The name of the property within the view model.
    public let name: String
    
    /// Optional metadata associated with the property (may be empty).
    public let metaData: String
    
    /// Creates a new ViewModelProperty instance.
    ///
    /// - Parameters:
    ///   - type: The data type of the property
    ///   - name: The name of the property
    ///   - metaData: Optional metadata for the property
    public init(type: DataType, name: String, metaData: String) {
        self.type = type
        self.name = name
        self.metaData = metaData
    }
    
    /// Creates a ViewModelProperty from a dictionary.
    /// - Parameter dictionary: Dictionary containing "type", "name", and "metaData" keys
    /// - Throws: An error if the dictionary is missing required keys or has invalid values
    init(from dictionary: [String: Any]) throws {
        guard let typeValue = dictionary["type"] as? NSNumber else {
            throw ViewModelPropertyError.missingType
        }
        guard let nameValue = dictionary["name"] as? String else {
            throw ViewModelPropertyError.missingName
        }
        let metaDataValue = dictionary["metaData"] as? String ?? ""

        guard let objcValue = RiveViewModelInstanceDataType(rawValue: typeValue.intValue),
        let type = DataType(objcValue: objcValue)
        else {
            throw ViewModelPropertyError.invalidType(typeValue.intValue)
        }
        self.type = type
        self.name = nameValue
        self.metaData = metaDataValue
    }
}

extension ViewModelProperty {
    /// A wrapper for the Objective-C view model instance data type enum.
    ///
    /// This enum wraps `RiveViewModelInstanceDataType` to avoid exposing Objective-C types
    /// in the public Swift API.
    @_spi(RiveExperimental)
    public enum DataType: Sendable, Equatable {
        /// None.
        case none
        /// String.
        case string
        /// Number.
        case number
        /// Boolean.
        case boolean
        /// Color.
        case color
        /// List.
        case list
        /// Enum.
        case `enum`
        /// Trigger.
        case trigger
        /// View Model.
        case viewModel
        /// Integer.
        case integer
        /// Symbol list index.
        case symbolListIndex
        /// Asset Image.
        case assetImage
        /// Artboard.
        case artboard
        /// Special case, this type is used to indicate it uses the input type.
        case input
        /// Any type (used for type checking).
        case any

        init?(objcValue: RiveViewModelInstanceDataType) {
            switch objcValue {
            case .none: self = .none
            case .string: self = .string
            case .number: self = .number
            case .boolean: self = .boolean
            case .color: self = .color
            case .list: self = .list
            case .enum: self = .enum
            case .trigger: self = .trigger
            case .viewModel: self = .viewModel
            case .integer: self = .integer
            case .symbolListIndex: self = .symbolListIndex
            case .assetImage: self = .assetImage
            case .artboard: self = .artboard
            case .input: self = .input
            case .any: self = .any
            @unknown default:
                return nil
            }
        }

        /// The underlying Objective-C type (for internal use).
        var objcValue: RiveViewModelInstanceDataType {
            switch self {
            case .none: return .none
            case .string: return .string
            case .number: return .number
            case .boolean: return .boolean
            case .color: return .color
            case .list: return .list
            case .enum: return .enum
            case .trigger: return .trigger
            case .viewModel: return .viewModel
            case .integer: return .integer
            case .symbolListIndex: return .symbolListIndex
            case .assetImage: return .assetImage
            case .artboard: return .artboard
            case .input: return .input
            case .any: return .any
            }
        }
    }
}

/// Errors that can occur when creating a ViewModelProperty from a dictionary.
@_spi(RiveExperimental)
public enum ViewModelPropertyError: LocalizedError, Equatable {
    /// An error indicating that the dictionary is missing the "type" key.
    case missingType
    /// An error indicating that the dictionary is missing the "name" key.
    case missingName
    /// An error indicating that a property type value that is not supported was used.
    case invalidType(Int)
    
    public var errorDescription: String? {
        switch self {
        case .missingType:
            return "Property is missing a type"
        case .missingName:
            return "Property is missing a name"
        case .invalidType(let value):
            return "Invalid property type: \(value)"
        }
    }
}

