//
//  RiveUIViewRepresentableTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import UIKit
import XCTest
@testable import RiveRuntime

final class RiveUIViewRepresentableTests: XCTestCase {
    @MainActor
    func test_hostedSynchronousView_preservesNativeViewAndCoordinatorWhenRiveOrKeyboardFocusChanges() async throws {
        let firstRive = try await makeHostedRive(handle: 1)
        let secondRive = try await makeHostedRive(handle: 2)
        let host = UIHostingController(rootView: RiveUIViewRepresentable(rive: nil).paused(true))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()

        let originalView = try hostedRiveView(in: host.view)
        let originalCoordinator = try XCTUnwrap(originalView.keyboardFocusDelegate)
        XCTAssertNil(originalView.rive)

        for (rive, requested) in [(firstRive, false), (firstRive, true), (secondRive, true), (secondRive, false)] {
            host.rootView = RiveUIViewRepresentable(rive: rive).paused(true).keyboardFocused(requested)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()

            let currentView = try hostedRiveView(in: host.view)
            XCTAssertTrue(currentView === originalView)
            XCTAssertTrue(currentView.keyboardFocusDelegate === originalCoordinator)
            XCTAssertTrue(currentView.rive === rive)
        }
    }

    @MainActor
    func test_hostedAsynchronousView_preservesNativeViewAndCoordinatorAfterLoadingAndKeyboardFocusChanges() async throws {
        let rive = try await makeHostedRive(handle: 1)
        let loaderStarted = expectation(description: "Hosted asynchronous loader started")
        let loaderReturned = expectation(description: "Hosted asynchronous loader returned")
        let resigned = expectation(description: "Asynchronous representable reports resignation result")
        let loaderRepeated = expectation(description: "Keyboard focus updates must not reload content")
        loaderRepeated.isInverted = true
        var finishLoading: CheckedContinuation<Void, Never>?
        var loaderCallCount = 0
        let representable = AsyncRiveUIViewRepresentable {
            loaderCallCount += 1
            guard loaderCallCount == 1 else {
                loaderRepeated.fulfill()
                return rive
            }
            await withCheckedContinuation { continuation in
                finishLoading = continuation
                loaderStarted.fulfill()
            }
            loaderReturned.fulfill()
            return rive
        }.paused(true)
        let host = UIHostingController(rootView: representable)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        await fulfillment(of: [loaderStarted], timeout: 1)

        let originalView = try hostedRiveView(in: host.view)
        let originalCoordinator = try XCTUnwrap(originalView.keyboardFocusDelegate)
        XCTAssertNil(originalView.rive)

        let continuation = try XCTUnwrap(finishLoading)
        continuation.resume()
        // The loader and assignment run on MainActor before this test resumes.
        await fulfillment(of: [loaderReturned], timeout: 1)
        XCTAssertTrue(originalView.rive === rive)
        XCTAssertTrue(try hostedRiveView(in: host.view) === originalView)
        XCTAssertTrue(originalView.keyboardFocusDelegate === originalCoordinator)

        for requested in [true, false] {
            host.rootView = representable.keyboardFocused(requested) { action, succeeded in
                XCTAssertEqual(action, .resign)
                XCTAssertTrue(succeeded)
                resigned.fulfill()
            }
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()

            let currentView = try hostedRiveView(in: host.view)
            XCTAssertTrue(currentView === originalView)
            XCTAssertTrue(currentView.keyboardFocusDelegate === originalCoordinator)
            XCTAssertTrue(currentView.rive === rive)
        }
        await fulfillment(of: [resigned], timeout: 1)
        await fulfillment(of: [loaderRepeated], timeout: 0.1)
        XCTAssertEqual(loaderCallCount, 1)
    }

    @MainActor
    func test_hostedView_refreshesResultCallbackWithoutRecreatingNativeViewOrCoordinator() async throws {
        let completed = expectation(description: "Latest hosted callback receives resignation result")
        let representable = RiveUIViewRepresentable(rive: nil)
        let host = UIHostingController(rootView: representable.keyboardFocused(true) { _, _ in
            XCTFail("Cancelled acquisition must not report a result")
        })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        let originalView = try hostedRiveView(in: host.view)
        let originalCoordinator = try XCTUnwrap(originalView.keyboardFocusDelegate)

        host.rootView = representable.keyboardFocused(false) { _, _ in
            XCTFail("A replaced callback must not receive the queued result")
        }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        // Only the closure changes while resignation is queued.
        host.rootView = representable.keyboardFocused(false) { action, succeeded in
            XCTAssertEqual(action, .resign)
            XCTAssertTrue(succeeded)
            completed.fulfill()
        }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        XCTAssertTrue(try hostedRiveView(in: host.view) === originalView)
        XCTAssertTrue(originalView.keyboardFocusDelegate === originalCoordinator)
        await fulfillment(of: [completed], timeout: 1)
    }

    @MainActor
    func test_keyboardFocused_initialFalseDoesNotBecomeOrResign() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let attempted = expectation(description: "Initial false must not attempt or report a transition")
        attempted.isInverted = true
        view.ready = true
        view.onBecomeKeyboardResponder = { attempted.fulfill() }
        view.onResignKeyboardResponder = { attempted.fulfill() }

        coordinator.update(requested: false, in: view) { _, _ in
            attempted.fulfill()
        }
        await fulfillment(of: [attempted], timeout: 0.1)

        XCTAssertTrue(view.keyboardFocusDelegate === coordinator)
        XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)
        XCTAssertTrue(view.resignKeyboardResponderCalls.isEmpty)
    }

    @MainActor
    func test_keyboardFocused_initialTrueWaitsForReadiness() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let requested = expectation(description: "Requested keyboard focus when ready")
        view.onBecomeKeyboardResponder = { requested.fulfill() }

        coordinator.update(requested: true, in: view)
        coordinator.update(requested: true, in: view)
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)

        view.ready = true
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        await fulfillment(of: [requested], timeout: 1)

        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_reportsRequestResultAfterNativeAttempt() async {
        for accepted in [false, true] {
            let view = MockKeyboardFocusView()
            let coordinator = RiveUIViewRepresentable.Coordinator()
            let completed = expectation(description: "Reported request result, accepted=\(accepted)")
            view.ready = true
            view.requestResult = accepted

            coordinator.update(requested: true, in: view) { action, succeeded in
                XCTAssertEqual(action, .become)
                XCTAssertEqual(succeeded, accepted)
                XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
                completed.fulfill()
            }
            XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)

            await fulfillment(of: [completed], timeout: 1)
        }
    }

    @MainActor
    func test_keyboardFocused_reportsResignationResultWithoutReadiness() async {
        for accepted in [false, true] {
            let view = MockKeyboardFocusView()
            let coordinator = RiveUIViewRepresentable.Coordinator()
            let completed = expectation(description: "Reported resignation result, accepted=\(accepted)")
            view.resignationResult = accepted
            coordinator.update(requested: true, in: view) { _, _ in
                XCTFail("Cancelled acquisition must not report a result")
            }

            coordinator.update(requested: false, in: view) { action, succeeded in
                XCTAssertEqual(action, .resign)
                XCTAssertEqual(succeeded, accepted)
                XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
                completed.fulfill()
            }
            XCTAssertTrue(view.resignKeyboardResponderCalls.isEmpty)

            await fulfillment(of: [completed], timeout: 1)
            XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)
        }
    }

    @MainActor
    func test_keyboardFocused_waitingRequestUsesLatestResultCallback() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let completed = expectation(description: "Latest callback receives the deferred result")
        coordinator.update(requested: true, in: view) { _, _ in
            XCTFail("Callback replaced while waiting for readiness must not run")
        }
        coordinator.update(requested: true, in: view) { action, succeeded in
            XCTAssertEqual(action, .become)
            XCTAssertTrue(succeeded)
            completed.fulfill()
        }

        view.ready = true
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        await fulfillment(of: [completed], timeout: 1)
        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_reentrantUpdateKeepsEachAttemptsResultCallback() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let acquired = expectation(description: "Original callback receives acquisition result")
        let resigned = expectation(description: "New callback receives resignation result")
        view.ready = true
        view.onBecomeKeyboardResponder = {
            coordinator.update(requested: false, in: view) { action, succeeded in
                XCTAssertEqual(action, .resign)
                XCTAssertTrue(succeeded)
                XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
                resigned.fulfill()
            }
        }
        defer { view.onBecomeKeyboardResponder = nil }

        coordinator.update(requested: true, in: view) { action, succeeded in
            XCTAssertEqual(action, .become)
            XCTAssertTrue(succeeded)
            XCTAssertTrue(view.resignKeyboardResponderCalls.isEmpty)
            acquired.fulfill()
        }

        await fulfillment(of: [acquired, resigned], timeout: 1, enforceOrder: true)
        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
        XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_keyWindowNotificationRetriesPendingReadiness() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let requested = expectation(description: "Requested keyboard focus after window became key")
        view.onBecomeKeyboardResponder = { requested.fulfill() }
        coordinator.update(requested: true, in: view)

        view.ready = true
        NotificationCenter.default.post(name: UIWindow.didBecomeKeyNotification, object: nil)
        await fulfillment(of: [requested], timeout: 1)

        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_unchangedTrueDoesNotRetryAfterRefusalOrFocusLoss() async {
        for accepted in [false, true] {
            let view = MockKeyboardFocusView()
            let coordinator = RiveUIViewRepresentable.Coordinator()
            let requested = expectation(description: "Initial request, accepted=\(accepted)")
            view.ready = true
            view.requestResult = accepted
            view.onBecomeKeyboardResponder = { requested.fulfill() }
            var resultCount = 0
            coordinator.update(requested: true, in: view) { _, _ in
                resultCount += 1
            }
            await fulfillment(of: [requested], timeout: 1)
            XCTAssertEqual(resultCount, 1)

            let repeated = expectation(description: "Must not repeat consumed request, accepted=\(accepted)")
            repeated.isInverted = true
            view.onBecomeKeyboardResponder = { repeated.fulfill() }
            view.ready = false
            coordinator.viewKeyboardFocusReadinessDidChange(view)
            view.ready = true
            coordinator.viewKeyboardFocusReadinessDidChange(view)
            coordinator.update(requested: true, in: view) { _, _ in
                XCTFail("An unchanged request or natural focus change must not report a new result")
            }
            NotificationCenter.default.post(name: UIWindow.didBecomeKeyNotification, object: nil)
            await fulfillment(of: [repeated], timeout: 0.1)

            XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
            XCTAssertEqual(resultCount, 1)
        }
    }

    @MainActor
    func test_keyboardFocused_falseCancelsQueuedRequest() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let relinquished = expectation(description: "Relinquished after cancelling request")
        view.ready = true
        view.onResignKeyboardResponder = { relinquished.fulfill() }

        coordinator.update(requested: true, in: view) { _, _ in
            XCTFail("A queued acquisition cancelled before execution must not report a result")
        }
        coordinator.update(requested: false, in: view)
        await fulfillment(of: [relinquished], timeout: 1)

        XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)
        XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_falseResignsWithoutReadiness() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let requested = expectation(description: "Acquired keyboard focus")
        let relinquished = expectation(description: "Relinquished without request readiness")
        view.ready = true
        view.onBecomeKeyboardResponder = { requested.fulfill() }
        view.onResignKeyboardResponder = { relinquished.fulfill() }

        coordinator.update(requested: true, in: view)
        await fulfillment(of: [requested], timeout: 1)

        view.ready = false
        coordinator.update(requested: false, in: view)
        XCTAssertTrue(view.resignKeyboardResponderCalls.isEmpty)
        await fulfillment(of: [relinquished], timeout: 1)

        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
        XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_pauseDoesNotCancelQueuedResignation() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let requested = expectation(description: "Acquired keyboard focus")
        let relinquished = expectation(description: "Relinquished despite pausing before task execution")
        view.ready = true
        view.onBecomeKeyboardResponder = { requested.fulfill() }
        view.onResignKeyboardResponder = { relinquished.fulfill() }
        coordinator.update(requested: true, in: view)
        await fulfillment(of: [requested], timeout: 1)

        coordinator.update(requested: false, in: view)
        view.isPaused = true
        await fulfillment(of: [relinquished], timeout: 1)

        let replayed = expectation(description: "Resume must not replay a relinquished request")
        replayed.isInverted = true
        view.onBecomeKeyboardResponder = { replayed.fulfill() }
        view.isPaused = false
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        coordinator.update(requested: false, in: view)
        await fulfillment(of: [replayed], timeout: 0.1)

        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
        XCTAssertEqual(view.resignKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_initiallyPausedRequestNeedsNewFalseTrueEdge() async {
        let view = MockKeyboardFocusView(isPaused: true)
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let replayed = expectation(description: "Must not replay a paused request")
        replayed.isInverted = true
        view.ready = true
        view.onBecomeKeyboardResponder = { replayed.fulfill() }

        coordinator.update(requested: true, in: view)
        view.isPaused = false
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        coordinator.update(requested: true, in: view)
        await fulfillment(of: [replayed], timeout: 0.1)

        let requested = expectation(description: "Fresh request after resume")
        view.onBecomeKeyboardResponder = { requested.fulfill() }
        coordinator.update(requested: false, in: view)
        coordinator.update(requested: true, in: view)
        await fulfillment(of: [requested], timeout: 1)
        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
    }

    @MainActor
    func test_keyboardFocused_viewCancellationNeedsNewFalseTrueEdge() async {
        for ready in [false, true] {
            let view = MockKeyboardFocusView()
            let coordinator = RiveUIViewRepresentable.Coordinator()
            let replayed = expectation(description: "Must not replay cancelled request, initially ready=\(ready)")
            replayed.isInverted = true
            view.ready = ready
            view.onBecomeKeyboardResponder = { replayed.fulfill() }

            coordinator.update(requested: true, in: view) { _, _ in
                XCTFail("A cancelled request must not report a result")
            }
            // Replacement and detachment deliver the same cancellation contract.
            coordinator.viewDidCancelKeyboardFocusRequest(view)
            view.ready = true
            coordinator.viewKeyboardFocusReadinessDidChange(view)
            coordinator.update(requested: true, in: view) { _, _ in
                XCTFail("An unchanged cancelled request must not report a result")
            }
            await fulfillment(of: [replayed], timeout: 0.1)

            let requested = expectation(description: "Fresh request after cancellation")
            view.onBecomeKeyboardResponder = { requested.fulfill() }
            coordinator.update(requested: false, in: view)
            coordinator.update(requested: true, in: view)
            await fulfillment(of: [requested], timeout: 1)
            XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
        }
    }

    @MainActor
    func test_keyboardFocused_ignoresReadinessFromPreviousView() async {
        let oldView = MockKeyboardFocusView()
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        coordinator.update(requested: false, in: oldView)
        coordinator.update(requested: false, in: view)
        XCTAssertNil(oldView.keyboardFocusDelegate)
        XCTAssertTrue(view.keyboardFocusDelegate === coordinator)

        coordinator.update(requested: true, in: view)
        view.ready = true
        let unexpectedRequest = expectation(description: "Old view must not trigger the new view's request")
        unexpectedRequest.isInverted = true
        view.onBecomeKeyboardResponder = { unexpectedRequest.fulfill() }
        coordinator.viewKeyboardFocusReadinessDidChange(oldView)
        coordinator.viewDidCancelKeyboardFocusRequest(oldView)
        await fulfillment(of: [unexpectedRequest], timeout: 0.1)

        let requested = expectation(description: "Current view readiness triggers request")
        view.onBecomeKeyboardResponder = { requested.fulfill() }
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        await fulfillment(of: [requested], timeout: 1)
        XCTAssertEqual(view.becomeKeyboardResponderCalls.count, 1)
        XCTAssertTrue(oldView.becomeKeyboardResponderCalls.isEmpty)
    }

    @MainActor
    func test_keyboardFocused_dismantleCancelsAndDetaches() async {
        let view = MockKeyboardFocusView()
        let coordinator = RiveUIViewRepresentable.Coordinator()
        let requested = expectation(description: "Dismantled coordinator must not request keyboard focus")
        requested.isInverted = true
        view.ready = true
        view.onBecomeKeyboardResponder = { requested.fulfill() }

        coordinator.update(requested: true, in: view) { _, _ in
            XCTFail("A dismantled coordinator must not report a result")
        }
        coordinator.dismantle()
        coordinator.viewKeyboardFocusReadinessDidChange(view)
        NotificationCenter.default.post(name: UIWindow.didBecomeKeyNotification, object: nil)
        await fulfillment(of: [requested], timeout: 0.1)

        XCTAssertNil(view.keyboardFocusDelegate)
        XCTAssertTrue(view.becomeKeyboardResponderCalls.isEmpty)
    }

    @MainActor
    func test_keyboardFocused_changesSynchronousRepresentableEquality() {
        let view = RiveUIViewRepresentable(rive: nil)

        XCTAssertEqual(view, view.keyboardFocused(false))
        XCTAssertNotEqual(view, view.keyboardFocused(true))
        XCTAssertEqual(view.keyboardFocused(true), view.keyboardFocused(true))

        let withResult = view.keyboardFocused(true) { _, _ in }
        let copy = withResult
        XCTAssertEqual(withResult, withResult)
        XCTAssertEqual(withResult, copy)
        XCTAssertNotEqual(withResult, view.keyboardFocused(true))
        XCTAssertNotEqual(withResult, view.keyboardFocused(true) { _, _ in })
    }

    @MainActor
    func test_keyboardFocused_changesAsynchronousRepresentableEquality() {
        let view = AsyncRiveUIViewRepresentable { throw UnusedLoaderError() }

        XCTAssertEqual(view, view.keyboardFocused(false))
        XCTAssertNotEqual(view, view.keyboardFocused(true))
        XCTAssertEqual(view.keyboardFocused(true), view.keyboardFocused(true))

        let withResult = view.keyboardFocused(true) { _, _ in }
        let copy = withResult
        XCTAssertEqual(withResult, withResult)
        XCTAssertEqual(withResult, copy)
        XCTAssertNotEqual(withResult, view.keyboardFocused(true))
        XCTAssertNotEqual(withResult, view.keyboardFocused(true) { _, _ in })
    }

    @MainActor
    func test_representables_shareKeyboardFocusCoordinator() {
        let action: AsyncRiveUIViewRepresentable.KeyboardResponderAction = .become
        XCTAssertEqual(action, RiveUIViewRepresentable.KeyboardResponderAction.become)
        let synchronous = RiveUIViewRepresentable(rive: nil).makeCoordinator()
        let asynchronous: RiveUIViewRepresentable.Coordinator = AsyncRiveUIViewRepresentable {
            throw UnusedLoaderError()
        }.makeCoordinator()
        let view = MockKeyboardFocusView()

        synchronous.update(requested: false, in: view)
        synchronous.dismantle()
        asynchronous.update(requested: false, in: view)

        XCTAssertTrue(view.keyboardFocusDelegate === asynchronous)
    }

    @MainActor
    private func hostedRiveView(in root: UIView) throws -> RiveUIView {
        func descendants(of view: UIView) -> [RiveUIView] {
            if let riveView = view as? RiveUIView { return [riveView] }
            return view.subviews.flatMap { descendants(of: $0) }
        }
        let views = descendants(of: root)
        XCTAssertEqual(views.count, 1)
        return try XCTUnwrap(views.first)
    }

    @MainActor
    private func makeHostedRive(handle: UInt64) async throws -> Rive {
        let (file, commandQueue, _, _) = await File.mock(fileHandle: handle)
        let messageGate = CommandQueueMessageGate(driver: commandQueue)
        let artboard = Artboard(
            dependencies: .init(artboardService: ArtboardService(dependencies: .init(
                commandQueue: commandQueue, messageGate: messageGate
            ))),
            artboardHandle: handle,
            sourceFile: file
        )
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: StateMachineService(dependencies: .init(
                commandQueue: commandQueue, messageGate: messageGate
            ))),
            stateMachineHandle: handle,
            sourceArtboard: artboard
        )
        return try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)
    }
}

private struct UnusedLoaderError: Error {}

@MainActor
private final class MockKeyboardFocusView: RiveUIView {
    struct BecomeKeyboardResponderCall {}
    struct ResignKeyboardResponderCall {}

    var ready = false
    var requestResult = true
    var resignationResult = true
    var onBecomeKeyboardResponder: (() -> Void)?
    var onResignKeyboardResponder: (() -> Void)?
    private(set) var becomeKeyboardResponderCalls: [BecomeKeyboardResponderCall] = []
    private(set) var resignKeyboardResponderCalls: [ResignKeyboardResponderCall] = []

    init(isPaused: Bool = false) {
        super.init(rive: nil, isPaused: isPaused)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var canRequestKeyboardFocus: Bool { ready }

    override func becomeKeyboardResponder() -> Bool {
        becomeKeyboardResponderCalls.append(.init())
        onBecomeKeyboardResponder?()
        return requestResult
    }

    override func resignKeyboardResponder() -> Bool {
        resignKeyboardResponderCalls.append(.init())
        onResignKeyboardResponder?()
        return resignationResult
    }
}
