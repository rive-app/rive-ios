//
//  RiveUIViewTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import UIKit
import XCTest
@testable import RiveRuntime

final class RiveUIViewTests: XCTestCase {
    @MainActor
    func test_pause_cancelsPendingKeyboardRequestOnlyOnTransition() {
        let view = RiveUIView(rive: nil)
        let delegate = MockKeyboardFocusDelegate()
        view.keyboardFocusDelegate = delegate

        view.isPaused = true
        view.isPaused = true
        view.isPaused = false

        XCTAssertEqual(delegate.cancellationCallCount, 1)
    }

    @MainActor
    func test_windowAttachmentReportsReadinessAndRemovalCancelsKeyboardRequest() {
        let view = RiveUIView(rive: nil)
        let delegate = MockKeyboardFocusDelegate()
        view.keyboardFocusDelegate = delegate
        let window = UIWindow()

        window.addSubview(view)
        XCTAssertEqual(delegate.readinessCallCount, 1)
        XCTAssertEqual(delegate.cancellationCallCount, 0)

        view.removeFromSuperview()
        XCTAssertEqual(delegate.cancellationCallCount, 1)
    }

    @MainActor
    func test_failedAsyncLoadCancelsPendingKeyboardRequest() async {
        let failed = expectation(description: "Async load failed")
        let errorDelegate = MockRiveUIViewDelegate()
        errorDelegate.onDidReceiveError = { _ in failed.fulfill() }
        let view = RiveUIView(rive: { throw KeyboardFocusLoadError() }, delegate: errorDelegate)
        let delegate = MockKeyboardFocusDelegate()
        view.keyboardFocusDelegate = delegate

        await fulfillment(of: [failed], timeout: 1)
        XCTAssertEqual(delegate.cancellationCallCount, 1)
    }

    @MainActor
    func test_becomeKeyboardResponder_withoutLoadedContentReturnsFalse() {
        let view = RiveUIView(rive: nil)
        XCTAssertFalse(view.becomeKeyboardResponder())
    }

    @MainActor
    func test_resignKeyboardResponder_withoutRenderingViewSucceeds() {
        let view = RiveUIView(rive: nil)

        XCTAssertTrue(view.resignKeyboardResponder())
    }

    @MainActor
    func test_resignKeyboardResponder_withoutOwnershipDoesNotRequestResignation() async {
        let view = RiveUIView(rive: nil, isPaused: true)
        let metalView = KeyboardResponderTestMetalView(frame: .zero, device: nil)
        await view.configureMetalViewForTesting(metalView)

        XCTAssertTrue(view.resignKeyboardResponder())
        XCTAssertEqual(metalView.resignCallCount, 0)
    }

    @MainActor
    func test_resignKeyboardResponder_releasesOwnershipOnceWhilePaused() async {
        let view = RiveUIView(rive: nil, isPaused: true)
        let metalView = KeyboardResponderTestMetalView(frame: .zero, device: nil)
        await view.configureMetalViewForTesting(metalView)
        metalView.ownsFirstResponder = true

        XCTAssertTrue(view.resignKeyboardResponder())
        XCTAssertFalse(metalView.isFirstResponder)
        XCTAssertTrue(view.resignKeyboardResponder())
        XCTAssertEqual(metalView.resignCallCount, 1)
    }

    @MainActor
    func test_resignKeyboardResponder_requiresOwnershipToEnd() async {
        for nativeResult in [false, true] {
            let view = RiveUIView(rive: nil, isPaused: true)
            let metalView = KeyboardResponderTestMetalView(frame: .zero, device: nil)
            await view.configureMetalViewForTesting(metalView)
            metalView.ownsFirstResponder = true
            metalView.releasesOwnership = false
            metalView.resignResult = nativeResult

            XCTAssertFalse(view.resignKeyboardResponder())
            XCTAssertTrue(metalView.isFirstResponder)
            XCTAssertEqual(metalView.resignCallCount, 1)
        }
    }

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

private struct KeyboardFocusLoadError: Error {}

/// Separates the native resignation result from confirmed responder ownership.
@MainActor
private final class KeyboardResponderTestMetalView: UIKitMetalView {
    var ownsFirstResponder = false
    var releasesOwnership = true
    var resignResult = true
    private(set) var resignCallCount = 0

    override var isFirstResponder: Bool { ownsFirstResponder }

    override func resignFirstResponder() -> Bool {
        resignCallCount += 1
        if releasesOwnership { ownsFirstResponder = false }
        return resignResult
    }
}

@MainActor
private final class MockKeyboardFocusDelegate: RiveUIViewKeyboardFocusDelegate {
    private(set) var readinessCallCount = 0
    private(set) var cancellationCallCount = 0

    func viewKeyboardFocusReadinessDidChange(_ view: RiveUIView) {
        readinessCallCount += 1
    }

    func viewDidCancelKeyboardFocusRequest(_ view: RiveUIView) {
        cancellationCallCount += 1
    }
}

@MainActor
private final class MockRiveUIViewDelegate: RiveUIViewDelegate {
    var onDidReceiveError: ((RiveUIViewError) -> Void)?

    func view(_ view: RiveUIView, didReceiveError: RiveUIViewError) {
        onDidReceiveError?(didReceiveError)
    }
}
