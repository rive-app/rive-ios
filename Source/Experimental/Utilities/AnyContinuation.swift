//
//  Response.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/21/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A type-erased wrapper for `CheckedContinuation` that allows storing continuations
/// of different types in a single dictionary.
///
/// Used by services to store continuations by request ID when command queue functions
/// are called. When listener callbacks are invoked, the continuation is looked up and
/// resumed with the result. Type checking is performed at runtime when resuming.
struct AnyContinuation {
    private let resume: (Result<Any, Error>) throws -> Void

    init<T>(_ continuation: CheckedContinuation<T, Error>) {
        resume = { result in
            switch result {
            case .success(let value):
                if let typedValue = value as? T {
                    continuation.resume(returning: typedValue)
                } else {
                    throw AnyContinuationError.typeMismatch(
                        expected: String(describing: T.self),
                        actual: String(describing: type(of: value))
                    )
                }
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }

    /// Resumes the continuation with the provided result.
    ///
    /// Performs runtime type checking to ensure the value type matches the continuation's
    /// expected type. Throws `AnyContinuationError.typeMismatch` if types don't match.
    func resume(with result: Result<Any, Error>) throws {
        try resume(result)
    }
}

/// Errors that can occur when resuming a type-erased continuation.
///
/// These errors are thrown when the value type doesn't match the continuation's expected type.
enum AnyContinuationError: LocalizedError {
    case typeMismatch(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)"
        }
    }
}
