//
//  ViewModelInstanceError.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/7/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation


/// Errors that can occur when working with view model instances.
@_spi(RiveExperimental)
public enum ViewModelInstanceError: LocalizedError {
    /// An error indicating that a property does not contain the correct data.
    case missingData
    case valueMismatch(String, String)
    case error(Error)
    case message(String)

    public var errorDescription: String? {
        switch self {
        case .missingData:
            "View model property is missing value data."
        case .valueMismatch(let expected, let actual):
            "Expected value of type \(expected), received value of type \(actual)."
        case .error(let error):
            error.localizedDescription
        case .message(let message):
            message
        }
    }
}
