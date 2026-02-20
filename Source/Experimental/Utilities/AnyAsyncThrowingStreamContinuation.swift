//
//  AnyAsyncThrowingStreamContinuation.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/21/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A type-erased wrapper for `AsyncThrowingStream.Continuation` that allows storing stream
/// continuations of different types in a single dictionary.
///
/// Used by services (e.g., `ViewModelInstanceService`) to store stream continuations by
/// request ID when subscribing to property changes. When listener callbacks are invoked,
/// values are yielded to the stream. Type checking is performed at runtime when yielding.
struct AnyAsyncThrowingStreamContinuation {
    private let yieldValue: (Any) throws -> Void
    private let finishStream: () -> Void
    private let finishStreamThrowing: (Error) -> Void

    init<T: Sendable>(_ continuation: AsyncThrowingStream<T, Error>.Continuation) {
        yieldValue = { value in
            if let typedValue = value as? T {
                continuation.yield(typedValue)
            } else {
                throw AnyAsyncThrowingStreamContinuationError.typeMismatch(
                    expected: String(describing: T.self),
                    actual: String(describing: type(of: value))
                )
            }
        }
        finishStream = {
            continuation.finish()
        }
        finishStreamThrowing = { error in
            continuation.finish(throwing: error)
        }
    }

    /// Yields a value to the stream continuation.
    ///
    /// Performs runtime type checking to ensure the value type matches the continuation's
    /// expected type.
    ///
    /// - Parameter value: The value to yield to the stream
    /// - Throws: `AnyAsyncThrowingStreamContinuationError.typeMismatch` if the value type doesn't match the continuation's expected type
    func yield(_ value: Any) throws {
        try yieldValue(value)
    }

    /// Finishes the stream successfully.
    func finish() {
        finishStream()
    }

    /// Finishes the stream with an error.
    func finish(throwing error: Error) {
        finishStreamThrowing(error)
    }
}

/// Errors that can occur when yielding to a type-erased stream continuation.
///
/// These errors are thrown when the value type doesn't match the continuation's expected type.
enum AnyAsyncThrowingStreamContinuationError: LocalizedError {
    case typeMismatch(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)"
        }
    }
}

