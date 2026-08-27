//
//  AsyncShared.swift
//  RiveExample
//
//  Copyright © 2026 Rive. All rights reserved.
//

/// Lazily caches a value and its in-flight creation so concurrent callers do
/// not repeat expensive initialization while the first call is suspended.
/// Failed initialization can be retried.
@MainActor
final class AsyncShared<Value> {
    private let makeValue: @MainActor () async throws -> Value
    private var cachedValue: Value?
    private var loadingTask: Task<Value, Error>?

    init(_ makeValue: @escaping @MainActor () async throws -> Value) {
        self.makeValue = makeValue
    }

    func value() async throws -> Value {
        if let cachedValue {
            return cachedValue
        }

        let task = loadingTask ?? Task {
            defer { loadingTask = nil }
            let value = try await makeValue()
            cachedValue = value
            return value
        }
        loadingTask = task

        return try await task.value
    }
}
