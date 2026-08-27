//
//  RiveUIViewTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

final class RiveUIViewTests: XCTestCase {
    @MainActor
    func test_rendererError_callsDelegateOnMainActor() async {
        let receivedError = expectation(description: "Received renderer error")
        let delegate = MockRiveUIViewDelegate()
        delegate.onDidReceiveError = { error in
            MainActor.preconditionIsolated()
            guard case .renderer(let description) = error else {
                XCTFail("Expected a renderer error")
                receivedError.fulfill()
                return
            }
            XCTAssertEqual(description, "Renderer failed")
            receivedError.fulfill()
        }
        let view = RiveUIView(rive: nil, delegate: delegate)
        let sendableView = UncheckedSendable(value: view)

        await Task.detached {
            let error = NSError(
                domain: "app.rive.renderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Renderer failed"]
            )
            sendableView.value.notifyDelegateOfRendererErrorForTesting(error)
        }.value

        await fulfillment(of: [receivedError], timeout: 1)
    }
}

@MainActor
private final class MockRiveUIViewDelegate: RiveUIViewDelegate {
    var onDidReceiveError: ((RiveUIViewError) -> Void)?

    func view(_ view: RiveUIView, didReceiveError: RiveUIViewError) {
        onDidReceiveError?(didReceiveError)
    }
}
