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
    private let resumeReturning: (sending Any) throws -> Void
    private let resumeThrowing: (Error) -> Void

    init<T: Sendable>(_ continuation: CheckedContinuation<T, Error>) {
        resumeReturning = { value in
            if let typedValue = value as? T {
                continuation.resume(returning: typedValue)
            } else {
                let error = AnyContinuationError.typeMismatch(
                    expected: String(describing: T.self),
                    actual: String(describing: type(of: value))
                )
                RiveLog.error(
                    tag: .rive,
                    error: error,
                    "[Rive] Failed to resume continuation"
                )
                throw error
            }
        }
        resumeThrowing = { error in
            continuation.resume(throwing: error)
        }
    }

    /// Resumes the continuation by returning a value.
    ///
    /// Performs runtime type checking to ensure the value type matches the continuation's
    /// expected type. Throws `AnyContinuationError.typeMismatch` if types don't match.
    func resume(returning value: sending Any) throws {
        try resumeReturning(value)
    }

    /// Resumes the continuation by throwing an error.
    func resume(throwing error: Error) {
        resumeThrowing(error)
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
