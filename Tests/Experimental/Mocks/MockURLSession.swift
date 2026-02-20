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

    init(resume: @escaping () -> Void) {
        _resume = resume
    }

    func resume() {
        _resume()
    }
}

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    typealias CompletionHandler = (Data?, URLResponse?, (any Error)?) -> Void
    private var _get: ((URL, CompletionHandler) -> Void)?

    func stubGet(_ callback: @escaping (URL, CompletionHandler) -> Void) {
        _get = callback
    }

    func get(url: URL, completionHandler: @escaping CompletionHandler) -> any URLSessionDataTaskProtocol {
        return MockURLSessionDataTask { [weak self] in
            self?._get?(url, completionHandler)
        }
    }
}
