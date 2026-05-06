//
//  MockURLSession.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 5/27/25.
//  Copyright © 2025 Rive. All rights reserved.
//

@testable import RiveRuntime

class MockURLSessionDataTask: URLSessionDataTaskProtocol, @unchecked Sendable {
    let _resume: () -> Void
    let _cancel: () -> Void

    init(resume: @escaping () -> Void, cancel: @escaping () -> Void = {}) {
        _resume = resume
        _cancel = cancel
    }

    func resume() {
        _resume()
    }

    func cancel() {
        _cancel()
    }
}

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    typealias CompletionHandler = @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    private var _get: ((URL, @escaping CompletionHandler) -> Void)?
    var onCancel: (() -> Void)?

    func stubGet(_ callback: @escaping (URL, @escaping CompletionHandler) -> Void) {
        _get = callback
    }

    func get(url: URL, completionHandler: @escaping @Sendable CompletionHandler) -> any URLSessionDataTaskProtocol {
        return MockURLSessionDataTask(
            resume: { [weak self] in
                self?._get?(url, completionHandler)
            },
            cancel: { [weak self] in
                self?.onCancel?()
            }
        )
    }
}
