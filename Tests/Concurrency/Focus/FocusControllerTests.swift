//
//  FocusControllerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

final class FocusControllerTests: XCTestCase {
    @MainActor
    func test_navigationKey_tabMapsDirectionAndReturnsConsumption() async {
        let results = [
            (moved: true, hasFocus: true, consumed: true),
            (moved: false, hasFocus: true, consumed: true),
            (moved: false, hasFocus: false, consumed: false),
            (moved: true, hasFocus: false, consumed: true),
        ]
        for modifiers: StateMachine.KeyModifiers in [[], [.shift]] {
            for result in results {
                let fixture = makeFixture()
                defer { fixture.controller.invalidate() }
                await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
                let traversal = CommandQueueFocusTraversalResult(
                    moved: result.moved,
                    focusState: .init(hasFocus: result.hasFocus, expectsKeyboardInput: false)
                )
                fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in traversal }
                fixture.commandQueue.stubFocusPreviousWithResultSynchronized { _ in traversal }

                XCTAssertEqual(fixture.controller.handleNavigationKey(
                    .tab, modifiers: modifiers, isPressed: true
                ), result.consumed)

                XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, modifiers.isEmpty ? 1 : 0)
                XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, modifiers.isEmpty ? 0 : 1)
                XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
                XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
                XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
            }
        }
    }

    @MainActor
    func test_navigationKey_arrowsMapDirectionAndReturnMovement() async {
        let directions: [(StateMachine.Key, StateMachine.FocusDirection)] = [
            (.left, .left), (.right, .right), (.up, .up), (.down, .down)
        ]
        for (key, direction) in directions {
            for moved in [false, true] {
                let fixture = makeFixture()
                defer { fixture.controller.invalidate() }
                await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
                fixture.commandQueue.stubFocusInDirectionSynchronized { _ in moved }

                XCTAssertEqual(fixture.controller.handleNavigationKey(
                    key, modifiers: [], isPressed: true
                ), moved)

                XCTAssertEqual(fixture.commandQueue.focusInDirectionSynchronizedCalls, [
                    .init(stateMachineHandle: 123, direction: direction)
                ])
                XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
                XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
                XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
                XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
            }
        }
    }

    @MainActor
    func test_navigationKey_releasesShortcutsAndOtherKeysDoNotTraverseOrWake() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let navigationKeys: [StateMachine.Key] = [.tab, .left, .right, .up, .down]

        for key in navigationKeys {
            for modifiers: StateMachine.KeyModifiers in [[], [.shift]] {
                XCTAssertFalse(fixture.controller.handleNavigationKey(key, modifiers: modifiers, isPressed: false))
            }
            for modifiers: StateMachine.KeyModifiers in [[.control], [.alt], [.meta], [.shift, .meta]] {
                XCTAssertFalse(fixture.controller.handleNavigationKey(key, modifiers: modifiers, isPressed: true))
            }
            if key != .tab {
                XCTAssertFalse(fixture.controller.handleNavigationKey(key, modifiers: [.shift], isPressed: true))
            }
        }
        for key: StateMachine.Key in [.enter, .space, .escape, .A] {
            XCTAssertFalse(fixture.controller.handleNavigationKey(key, modifiers: [], isPressed: true))
        }

        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
    }

    @MainActor
    func test_navigationKey_unavailablePausedAndInvalidatedControllersIgnoreNavigation() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }

        func assertNavigationIsIgnored() {
            XCTAssertFalse(fixture.controller.handleNavigationKey(.tab, modifiers: [], isPressed: true))
            XCTAssertFalse(fixture.controller.handleNavigationKey(.tab, modifiers: [.shift], isPressed: true))
            XCTAssertFalse(fixture.controller.handleNavigationKey(.right, modifiers: [], isPressed: true))
            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
            XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
        }

        assertNavigationIsIgnored()

        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: nil)
        fixture.controller.isPaused = true
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        assertNavigationIsIgnored()

        fixture.controller.isPaused = false
        fixture.controller.invalidate()
        fixture.focusSystem.isFocusable = true
        assertNavigationIsIgnored()
    }

    @MainActor
    func test_init_requiresSystemAndStartsNotFocusable() {
        for hasNativeFocus in [false, true] {
            let fixture = makeFixture(systemIsFocusable: true, hasNativeFocus: hasNativeFocus)

            XCTAssertFalse(fixture.focusSystem.isFocusable)
            XCTAssertTrue(fixture.focusSystem.delegate === fixture.controller)

            fixture.controller.invalidate()
        }
    }

    @MainActor
    func test_inheritedNativeFocus_pausedExitClearsFocusAndDisablesTraversal() async {
        let fixture = makeFixture(hasNativeFocus: true)
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)

        fixture.controller.isPaused = true

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, false)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)

        fixture.focusSystem.exit()

        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
    }

    @MainActor
    func test_retainedNativeFocus_waitsForSnapshotAndSeedsOnlyOnce() async throws {
        let fixture = makeFixture(hasNativeFocus: true, defaultEntryDirection: .next)
        defer { fixture.controller.invalidate() }
        let requested = expectation(description: "initial snapshot requested")
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.service] handle, requestID in
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }

        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)

        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        let applied = expectation(description: "initial snapshot applied")
        fixture.controller.onFocusStateApplied = { _ in applied.fulfill() }
        fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }
        fixture.service.onFocusStateReceived(
            request.stateMachineHandle, requestID: request.requestID,
            focusState: .init(hasFocus: false, expectsKeyboardInput: false)
        )
        await fulfillment(of: [applied], timeout: 1)
        fixture.controller.onFocusStateApplied = nil

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, true)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)

        // A later authored blur must not restart attachment-time traversal.
        await respondToFocusState(.init(hasFocus: false, expectsKeyboardInput: false), in: fixture)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, false)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
    }

    @MainActor
    func test_retainedNativeFocus_preservesNodeAlreadySelectedByReplacement() async {
        let fixture = makeFixture(hasNativeFocus: true, defaultEntryDirection: .next)
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, focusState: .init(
            hasFocus: true, expectsKeyboardInput: false
        ), in: fixture)

        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        await respondToFocusState(.init(hasFocus: false, expectsKeyboardInput: false), in: fixture)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
    }

    @MainActor
    func test_defaultEntryDirection_doesNotSeedWithoutNativeFocus() async {
        let fixture = makeFixture(defaultEntryDirection: .next)
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)

        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
    }

    @MainActor
    func test_retainedNativeFocus_exitBeforeReadinessCancelsSeeding() async {
        let fixture = makeFixture(hasNativeFocus: true, defaultEntryDirection: .next)
        defer { fixture.controller.invalidate() }
        fixture.focusSystem.exit()

        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)

        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)

        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .previous)
        XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, 1)
    }

    @MainActor
    func test_retainedNativeFocus_pauseDefersSeedingUntilResumeWithoutRetryingFailure() async {
        let fixture = makeFixture(hasNativeFocus: true, defaultEntryDirection: .next)
        defer { fixture.controller.invalidate() }
        fixture.controller.isPaused = true
        fixture.controller.didAdvance()

        XCTAssertTrue(fixture.commandQueue.requestHasFocusNodesCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        fixture.controller.isPaused = false
        // The default mock traversal leaves focus empty, as when no node accepts entry.
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)

        await respondToFocusState(.init(hasFocus: false, expectsKeyboardInput: false), in: fixture)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
    }

    @MainActor
    func test_didAdvance_updatesFocusabilityFromStateMachine() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }

        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        XCTAssertTrue(fixture.focusSystem.isFocusable)

        await respondToFocusSnapshot(hasFocusNodes: false, in: fixture)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertNil(fixture.controller.focusState)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 2)
    }

    @MainActor
    func test_didAdvance_withoutNodesPollsAvailabilityButNotFocusState() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let firstRequested = expectation(description: "initial availability requested")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in firstRequested.fulfill() }
        fixture.commandQueue.stubRequestFocusState { _, _ in XCTFail("No nodes require no focus snapshot") }
        fixture.controller.didAdvance()
        await fulfillment(of: [firstRequested], timeout: 1)

        for iteration in 0..<3 {
            let pending = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
            let refreshed = expectation(description: "availability refreshed after an empty result")
            fixture.commandQueue.stubRequestHasFocusNodes { _, _ in refreshed.fulfill() }
            fixture.controller.didAdvance()
            fixture.controller.didAdvance()
            fixture.service.onHasFocusNodesReceived(
                pending.stateMachineHandle, requestID: pending.requestID, hasFocusNodes: false
            )
            // The follow-up proves the preceding availability response was applied.
            await fulfillment(of: [refreshed], timeout: 1)
            XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, iteration + 2)
            XCTAssertTrue(fixture.commandQueue.requestFocusStateCalls.isEmpty)
            XCTAssertNil(fixture.controller.focusState)
            XCTAssertFalse(fixture.focusSystem.isFocusable)
        }
    }

    @MainActor
    func test_nodesDisappear_discardsPendingSnapshotAndRefreshesWhenNodesReturn() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, focusState: .init(
            hasFocus: true, expectsKeyboardInput: false
        ), in: fixture)
        let availabilityRequested = expectation(description: "availability requested")
        let stateRequested = expectation(description: "snapshot requested before nodes disappear")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in availabilityRequested.fulfill() }
        fixture.commandQueue.stubRequestFocusState { _, _ in stateRequested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [availabilityRequested, stateRequested], timeout: 1)
        let availability = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
        let snapshot = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)

        let cancelled = expectation(description: "obsolete snapshot cancelled")
        fixture.service.onRequestCancelled = { requestID in
            XCTAssertEqual(requestID, snapshot.requestID)
            cancelled.fulfill()
        }
        let disabled = expectation(description: "missing nodes disable focus")
        fixture.focusSystem.onIsFocusableChanged = { if !$0 { disabled.fulfill() } }
        let availabilityRefreshed = expectation(description: "availability continues polling")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in availabilityRefreshed.fulfill() }
        fixture.commandQueue.stubRequestFocusState { _, _ in XCTFail("No snapshot while nodes are absent") }
        fixture.controller.didAdvance()
        fixture.controller.didAdvance()
        fixture.service.onHasFocusNodesReceived(
            availability.stateMachineHandle, requestID: availability.requestID, hasFocusNodes: false
        )
        await fulfillment(of: [cancelled, disabled, availabilityRefreshed], timeout: 1)
        fixture.service.onRequestCancelled = nil
        fixture.focusSystem.onIsFocusableChanged = nil
        XCTAssertNil(fixture.controller.focusState)
        await discardFocusStateResponse(requestID: snapshot.requestID, hasFocus: true, in: fixture)
        XCTAssertNil(fixture.controller.focusState)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 2)

        let recovery = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
        let freshSnapshotRequested = expectation(description: "returning nodes request a fresh snapshot")
        fixture.commandQueue.stubRequestFocusState { _, _ in freshSnapshotRequested.fulfill() }
        // No further advance: availability alone must start the recovery query.
        fixture.service.onHasFocusNodesReceived(
            recovery.stateMachineHandle, requestID: recovery.requestID, hasFocusNodes: true
        )
        await fulfillment(of: [freshSnapshotRequested], timeout: 1)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        let freshSnapshot = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        let enabled = expectation(description: "fresh snapshot restores eligibility")
        fixture.focusSystem.onIsFocusableChanged = { if $0 { enabled.fulfill() } }
        fixture.service.onFocusStateReceived(
            freshSnapshot.stateMachineHandle, requestID: freshSnapshot.requestID,
            focusState: .init(hasFocus: false, expectsKeyboardInput: false)
        )
        await fulfillment(of: [enabled], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 3)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)

        // The formerly focused node must not suppress traversal on native reentry.
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
    }

    @MainActor
    func test_didAdvance_allowsOnlyOneAvailabilityRequestAtATime() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let requested = expectation(description: "availability requested")

        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in
            requested.fulfill()
        }

        fixture.controller.didAdvance()
        fixture.controller.didAdvance()

        await fulfillment(of: [requested], timeout: 1)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 1)
    }

    @MainActor
    func test_didAdvance_coalescesPendingAvailabilityRefreshWithoutAnotherAdvance() async throws {
        for latestHasFocusNodes in [false, true] {
            let fixture = makeFixture()
            defer { fixture.controller.invalidate() }
            await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
            if latestHasFocusNodes {
                await respondToFocusSnapshot(hasFocusNodes: false, in: fixture)
            }
            fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
                service?.onFocusStateReceived(
                    handle, requestID: requestID,
                    focusState: .init(hasFocus: false, expectsKeyboardInput: false)
                )
            }
            let initialCallCount = fixture.commandQueue.requestHasFocusNodesCalls.count

            let requested = expectation(description: "availability requested")
            fixture.commandQueue.stubRequestHasFocusNodes { _, _ in requested.fulfill() }
            fixture.controller.didAdvance()
            await fulfillment(of: [requested], timeout: 1)
            let pending = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)

            // These advances change availability, then the machine settles.
            fixture.controller.didAdvance()
            fixture.controller.didAdvance()
            XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, initialCallCount + 1)

            let refreshed = expectation(description: "coalesced availability requested")
            fixture.commandQueue.stubRequestHasFocusNodes { _, _ in refreshed.fulfill() }
            fixture.service.onHasFocusNodesReceived(
                pending.stateMachineHandle, requestID: pending.requestID, hasFocusNodes: !latestHasFocusNodes
            )
            await fulfillment(of: [refreshed], timeout: 1)
            XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, initialCallCount + 2)
            let latest = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
            XCTAssertNotEqual(latest.requestID, pending.requestID)

            let applied = expectation(description: "latest availability applied")
            fixture.focusSystem.onIsFocusableChanged = { isFocusable in
                XCTAssertEqual(isFocusable, latestHasFocusNodes)
                applied.fulfill()
            }
            fixture.service.onHasFocusNodesReceived(
                latest.stateMachineHandle, requestID: latest.requestID, hasFocusNodes: latestHasFocusNodes
            )
            await fulfillment(of: [applied], timeout: 1)
            fixture.focusSystem.onIsFocusableChanged = nil
            XCTAssertEqual(fixture.focusSystem.isFocusable, latestHasFocusNodes)
            XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, initialCallCount + 2)
        }
    }

    @MainActor
    func test_pauseResume_refreshesAvailabilityWithoutWaitingForCancelledRequest() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let initialRequest = expectation(description: "initial availability requested")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in initialRequest.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [initialRequest], timeout: 1)
        let original = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)

        let replacementRequested = expectation(description: "resume availability requested")
        let snapshotApplied = expectation(description: "resume snapshot applied")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in replacementRequested.fulfill() }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: false, expectsKeyboardInput: false
            ))
        }
        fixture.controller.onFocusStateApplied = { _ in snapshotApplied.fulfill() }

        // The resume frame must query availability even before cancellation cleanup can run.
        fixture.controller.isPaused = true
        fixture.controller.isPaused = false
        fixture.controller.didAdvance()
        await fulfillment(of: [replacementRequested], timeout: 1)
        XCTAssertTrue(fixture.commandQueue.requestFocusStateCalls.isEmpty)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 2)
        let replacement = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
        XCTAssertNotEqual(original.requestID, replacement.requestID)

        let discarded = expectation(description: "cancelled availability response discarded")
        fixture.service.onFocusResponseDiscarded = { requestID in
            XCTAssertEqual(requestID, original.requestID)
            discarded.fulfill()
        }
        fixture.service.onHasFocusNodesReceived(
            original.stateMachineHandle, requestID: original.requestID, hasFocusNodes: false
        )
        await fulfillment(of: [discarded], timeout: 1)
        fixture.service.onFocusResponseDiscarded = nil

        // Another advance must not replace the still-pending resume request.
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in }
        fixture.controller.didAdvance()
        XCTAssertTrue(fixture.commandQueue.requestFocusStateCalls.isEmpty)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 2)

        let enabled = expectation(description: "replacement availability enables focus")
        fixture.focusSystem.onIsFocusableChanged = { if $0 { enabled.fulfill() } }
        fixture.service.onHasFocusNodesReceived(
            replacement.stateMachineHandle, requestID: replacement.requestID, hasFocusNodes: true
        )
        await fulfillment(of: [enabled, snapshotApplied], timeout: 1)
        fixture.controller.onFocusStateApplied = nil
        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_didAdvance_waitsForInitialFocusStateBeforeBecomingFocusable() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let availabilityRequested = expectation(description: "availability requested")
        let focusStateRequested = expectation(description: "focus state requested")
        var focusStateRequest: (stateMachineHandle: UInt64, requestID: UInt64)?

        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.service] handle, requestID in
            availabilityRequested.fulfill()
            service?.onHasFocusNodesReceived(
                handle,
                requestID: requestID,
                hasFocusNodes: true
            )
        }
        fixture.commandQueue.stubRequestFocusState { handle, requestID in
            focusStateRequest = (handle, requestID)
            focusStateRequested.fulfill()
        }

        fixture.controller.didAdvance()
        await fulfillment(
            of: [availabilityRequested, focusStateRequested],
            timeout: 1
        )

        XCTAssertFalse(fixture.focusSystem.isFocusable)

        let becameFocusable = expectation(description: "became focusable")
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            if isFocusable {
                becameFocusable.fulfill()
            }
        }
        guard let focusStateRequest else {
            XCTFail("Expected focus state request")
            return
        }
        fixture.service.onFocusStateReceived(
            focusStateRequest.stateMachineHandle,
            requestID: focusStateRequest.requestID,
            focusState: CommandQueueFocusState(
                hasFocus: false,
                expectsKeyboardInput: false
            )
        )

        await fulfillment(of: [becameFocusable], timeout: 1)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_didAdvance_requestsInitialSnapshotOnlyAfterNodesAppear() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let availabilityRequested = expectation(description: "availability requested")
        let stateApplied = expectation(description: "focus state applied")
        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in availabilityRequested.fulfill() }
        fixture.controller.onFocusStateApplied = { _ in stateApplied.fulfill() }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: true, expectsKeyboardInput: false
            ))
        }

        fixture.controller.didAdvance()
        await fulfillment(of: [availabilityRequested], timeout: 1)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.requestFocusStateCalls.isEmpty)

        let enabled = expectation(description: "focus enabled after availability")
        fixture.focusSystem.onIsFocusableChanged = { if $0 { enabled.fulfill() } }
        let request = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
        fixture.service.onHasFocusNodesReceived(
            request.stateMachineHandle, requestID: request.requestID, hasFocusNodes: true
        )
        await fulfillment(of: [enabled, stateApplied], timeout: 1)
        fixture.controller.onFocusStateApplied = nil
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_didAdvance_availabilityFailureDisablesFocusAndSuccessfulResponseRestoresIt() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let disabled = expectation(description: "focus disabled after availability error")
        fixture.focusSystem.onIsFocusableChanged = { if !$0 { disabled.fulfill() } }
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.service] handle, requestID in
            service?.onStateMachineError(handle, requestID: requestID, message: "Focus nodes unavailable")
        }
        fixture.controller.didAdvance()
        await fulfillment(of: [disabled], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil
        XCTAssertNil(fixture.controller.focusState)
        XCTAssertFalse(fixture.controller.handleNavigationKey(.tab, modifiers: [], isPressed: true))
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
    }

    @MainActor
    func test_pauseAndInvalidate_discardLateResponsesAndCoalescedRefreshes() async throws {
        for invalidate in [false, true] {
            let fixture = makeFixture()
            defer { fixture.controller.invalidate() }
            await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
            let availabilityRequested = expectation(description: "availability requested")
            let stateRequested = expectation(description: "state requested")
            fixture.commandQueue.stubRequestHasFocusNodes { _, _ in availabilityRequested.fulfill() }
            fixture.commandQueue.stubRequestFocusState { _, _ in stateRequested.fulfill() }
            fixture.controller.didAdvance()
            await fulfillment(of: [availabilityRequested, stateRequested], timeout: 1)
            let availability = try XCTUnwrap(fixture.commandQueue.requestHasFocusNodesCalls.last)
            let state = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
            let cancelled = expectation(description: "both pending requests cancelled")
            cancelled.expectedFulfillmentCount = 2
            fixture.service.onRequestCancelled = { requestID in
                XCTAssertTrue([availability.requestID, state.requestID].contains(requestID))
                cancelled.fulfill()
            }

            fixture.controller.didAdvance()
            fixture.controller.didAdvance()
            if invalidate {
                fixture.controller.invalidate()
            } else {
                fixture.controller.isPaused = true
            }
            await fulfillment(of: [cancelled], timeout: 1)
            fixture.service.onRequestCancelled = nil
            XCTAssertFalse(fixture.focusSystem.isFocusable)

            let discarded = expectation(description: "both late responses discarded")
            discarded.expectedFulfillmentCount = 2
            fixture.service.onFocusResponseDiscarded = { requestID in
                XCTAssertTrue([availability.requestID, state.requestID].contains(requestID))
                discarded.fulfill()
            }
            fixture.service.onHasFocusNodesReceived(
                availability.stateMachineHandle, requestID: availability.requestID, hasFocusNodes: true
            )
            fixture.service.onFocusStateReceived(
                state.stateMachineHandle, requestID: state.requestID,
                focusState: .init(hasFocus: true, expectsKeyboardInput: true)
            )
            await fulfillment(of: [discarded], timeout: 1)

            XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 2)
            XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 2)
            XCTAssertFalse(fixture.focusSystem.isFocusable)
            if invalidate {
                XCTAssertNil(fixture.controller.focusState)
            } else {
                XCTAssertEqual(fixture.controller.focusState, .init(hasFocus: false, expectsKeyboardInput: false))
            }
            XCTAssertFalse(fixture.controller.handleNavigationKey(.tab, modifiers: [], isPressed: true))
            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, invalidate ? 1 : 0)
            XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
        }
    }

    @MainActor
    func test_didAdvance_appliesDelayedSnapshotsAndCoalescesFurtherAdvances() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let firstRequested = expectation(description: "first focus state requested")
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.service] handle, requestID in
            service?.onHasFocusNodesReceived(
                handle, requestID: requestID, hasFocusNodes: true
            )
        }
        fixture.commandQueue.stubRequestFocusState { _, _ in firstRequested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [firstRequested], timeout: 1)
        XCTAssertNil(fixture.controller.focusState)
        XCTAssertFalse(fixture.focusSystem.isFocusable)

        // Every response arrives after more advances. Polling must still make
        // progress rather than cancelling every answer during an animation.
        for iteration in 0..<3 {
            let pending = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
            let applied = expectation(description: "delayed snapshot applied")
            let followUp = expectation(description: "coalesced snapshot requested")
            let hasFocus = iteration.isMultiple(of: 2)
            fixture.controller.onFocusStateApplied = { state in
                XCTAssertEqual(state.hasFocus, hasFocus)
                applied.fulfill()
            }
            fixture.commandQueue.stubRequestFocusState { _, _ in followUp.fulfill() }

            fixture.controller.didAdvance()
            fixture.controller.didAdvance()
            fixture.controller.didAdvance()
            fixture.service.onFocusStateReceived(
                pending.stateMachineHandle, requestID: pending.requestID,
                focusState: .init(hasFocus: hasFocus, expectsKeyboardInput: false)
            )
            await fulfillment(of: [applied, followUp], timeout: 1)
            XCTAssertTrue(fixture.focusSystem.isFocusable)
            XCTAssertEqual(fixture.controller.focusState?.hasFocus, hasFocus)
            XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, iteration + 2)
        }

        // Once advances stop, the final follow-up still applies and does not
        // start another query by itself.
        let last = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        let finalApplied = expectation(description: "final snapshot applied without another advance")
        fixture.controller.onFocusStateApplied = { _ in finalApplied.fulfill() }
        fixture.commandQueue.stubRequestFocusState { _, _ in XCTFail("Unexpected extra snapshot request") }
        fixture.service.onFocusStateReceived(
            last.stateMachineHandle, requestID: last.requestID,
            focusState: .init(hasFocus: false, expectsKeyboardInput: false)
        )
        await fulfillment(of: [finalApplied], timeout: 1)
        fixture.controller.onFocusStateApplied = nil
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 4)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, false)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_keyboardInput_cancelsDelayedSnapshotWithoutDisturbingReplacement() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let requested = expectation(description: "pre-input snapshot requested")
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)
        let old = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)

        let cancelled = expectation(description: "pre-input snapshot cancelled")
        fixture.service.onRequestCancelled = { requestID in
            if requestID == old.requestID { cancelled.fulfill() }
        }
        let replacementRequested = expectation(description: "post-input snapshot requested")
        fixture.commandQueue.stubRequestFocusState { _, _ in replacementRequested.fulfill() }
        fixture.controller.didAdvance()
        fixture.controller.prepareForKeyboardInput()
        // Start the replacement before cancellation cleanup has a chance to run.
        fixture.controller.didAdvance()
        await fulfillment(of: [cancelled, replacementRequested], timeout: 1)
        let replacement = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        XCTAssertNotEqual(old.requestID, replacement.requestID)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 3)

        await discardFocusStateResponse(requestID: old.requestID, hasFocus: true, in: fixture)
        let applied = expectation(description: "replacement snapshot applied")
        let followUp = expectation(description: "replacement coalesces another advance")
        fixture.controller.onFocusStateApplied = { state in
            XCTAssertFalse(state.hasFocus)
            applied.fulfill()
        }
        fixture.commandQueue.stubRequestFocusState { _, _ in followUp.fulfill() }
        fixture.controller.didAdvance()
        fixture.service.onFocusStateReceived(
            replacement.stateMachineHandle, requestID: replacement.requestID,
            focusState: .init(hasFocus: false, expectsKeyboardInput: false)
        )
        await fulfillment(of: [applied, followUp], timeout: 1)
        fixture.controller.onFocusStateApplied = nil
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 4)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, false)
    }

    @MainActor
    func test_didAdvance_whenFocusStateFails_disablesFocus() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(
            hasFocusNodes: true,
            focusState: .init(
                hasFocus: true,
                expectsKeyboardInput: false
            ),
            in: fixture
        )
        let becameNotFocusable = expectation(description: "became not focusable")
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            if !isFocusable {
                becameNotFocusable.fulfill()
            }
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            service?.onStateMachineError(
                handle,
                requestID: requestID,
                message: "Unable to request focus state"
            )
        }

        fixture.controller.didAdvance()

        await fulfillment(of: [becameNotFocusable], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil
        XCTAssertNil(fixture.controller.focusState)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_traversal_lateSnapshotCannotLoseAcquiredNode() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let requested = expectation(description: "focus state requested")
        let cancelled = expectation(description: "focus state request cancelled")
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        fixture.service.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }
        fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }

        XCTAssertTrue(fixture.controller.traverse(.next))
        await fulfillment(of: [cancelled], timeout: 1)

        await discardFocusStateResponse(
            requestID: request.requestID,
            hasFocus: false,
            in: fixture
        )
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)

        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.controller.focusState?.hasFocus, true)
    }

    @MainActor
    func test_failedDirectionalTraversal_wakesAndRefreshesFocusAfterDiscardingOldSnapshot() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, focusState: .init(
            hasFocus: true, expectsKeyboardInput: false
        ), in: fixture)
        let requested = expectation(description: "pre-traversal snapshot requested")
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        let cancelled = expectation(description: "pre-traversal snapshot cancelled")
        fixture.service.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }
        fixture.commandQueue.stubFocusInDirectionSynchronized { _ in false }

        // Invoke focus directly so keyboard delivery cannot supply the wake.
        XCTAssertFalse(fixture.controller.focusInDirection(.right))
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        await fulfillment(of: [cancelled], timeout: 1)
        await discardFocusStateResponse(requestID: request.requestID, hasFocus: true, in: fixture)

        let current = StateMachine.FocusState(hasFocus: false, expectsKeyboardInput: false)
        await respondToFocusState(current, in: fixture)
        XCTAssertEqual(fixture.controller.focusState, current)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_prepareForKeyboardInput_cancelsPendingSnapshot() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let requested = expectation(description: "focus state requested")
        let cancelled = expectation(description: "focus state request cancelled")
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        fixture.service.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }

        fixture.controller.prepareForKeyboardInput()
        await fulfillment(of: [cancelled], timeout: 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 0)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
    }

    @MainActor
    func test_exit_lateSnapshotCannotPreventReentry() async throws {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        let requested = expectation(description: "focus state requested")
        let cancelled = expectation(description: "focus state request cancelled")
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.controller.didAdvance()
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        fixture.service.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }

        fixture.focusSystem.exit()
        await fulfillment(of: [cancelled], timeout: 1)

        await discardFocusStateResponse(
            requestID: request.requestID,
            hasFocus: true,
            in: fixture
        )
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)

        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
    }

    @MainActor
    func test_didAdvance_restoresFocusabilityAfterFailedPoll() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        let focusedState = StateMachine.FocusState(hasFocus: true, expectsKeyboardInput: false)
        await respondToFocusSnapshot(
            hasFocusNodes: true,
            focusState: focusedState,
            in: fixture
        )
        let disabled = expectation(description: "focus disabled after error")
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            if !isFocusable { disabled.fulfill() }
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            service?.onStateMachineError(handle, requestID: requestID, message: "Focus state unavailable")
        }
        fixture.controller.didAdvance()
        await fulfillment(of: [disabled], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil

        await respondToFocusState(focusedState, in: fixture)

        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_exit_clearsRiveFocusAndRequestsWake() {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }

        fixture.focusSystem.exit()

        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
    }

    @MainActor
    func test_losingFocusNodes_ignoresTraversal() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)

        await respondToFocusSnapshot(hasFocusNodes: false, in: fixture)
        XCTAssertFalse(fixture.controller.traverse(.next))

        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_pausePreservesFocusAndIgnoresInputAndPolling() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: nil)

        fixture.controller.isPaused = true
        XCTAssertFalse(fixture.controller.traverse(.previous))
        fixture.controller.didAdvance()

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 1)
    }

    @MainActor
    func test_pauseWithoutNativeExit_preservesNodeOnResume() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(
            hasFocusNodes: true,
            focusState: .init(
                hasFocus: true,
                expectsKeyboardInput: false
            ),
            in: fixture
        )

        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        fixture.controller.isPaused = true
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        fixture.controller.isPaused = false

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.controller.focusState, .init(hasFocus: true, expectsKeyboardInput: false))
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)

        fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }
        XCTAssertTrue(fixture.controller.traverse(.next))
        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        fixture.focusSystem.exit()
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
    }

    @MainActor
    func test_pausedExit_clearsFocusAndResumeRequiresNewEntry() async {
        for direction: FocusTraversalDirection in [.next, .previous] {
            let fixture = makeFixture()
            defer { fixture.controller.invalidate() }
            await respondToFocusSnapshot(hasFocusNodes: true, focusState: .init(
                hasFocus: true, expectsKeyboardInput: false
            ), in: fixture)
            fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction)
            fixture.controller.isPaused = true
            XCTAssertTrue(fixture.focusSystem.isFocusable)
            fixture.focusSystem.exit()
            XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
            XCTAssertFalse(fixture.focusSystem.isFocusable)

            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            fixture.controller.isPaused = false

            XCTAssertTrue(fixture.focusSystem.isFocusable)
            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction)

            XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, direction == .next ? 1 : 0)
            XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, direction == .previous ? 1 : 0)
        }
    }

    @MainActor
    func test_pauseOutsideRive_excludesViewUntilResumeWithoutTraversing() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.controller.isPaused = true
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        fixture.controller.isPaused = false

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .previous)
        XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, 1)
    }

    @MainActor
    func test_invalidateIsIdempotentAndIgnoresFurtherEvents() {
        let fixture = makeFixture(systemIsFocusable: true)

        fixture.controller.invalidate()
        fixture.controller.invalidate()
        fixture.controller.didAdvance()
        _ = fixture.controller.traverse(.next)
        fixture.focusSystem.exit()

        XCTAssertFalse(fixture.focusSystem.isFocusable)
        XCTAssertNil(fixture.focusSystem.delegate)
        XCTAssertEqual(fixture.focusSystem.invalidateCallCount, 1)
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.requestHasFocusNodesCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    private func discardFocusStateResponse(
        requestID: UInt64,
        hasFocus: Bool,
        in fixture: FocusControllerFixture
    ) async {
        let discarded = expectation(description: "late focus snapshot discarded")
        fixture.service.onFocusResponseDiscarded = { discardedID in
            XCTAssertEqual(discardedID, requestID)
            discarded.fulfill()
        }
        fixture.service.onFocusStateReceived(
            123, requestID: requestID,
            focusState: .init(hasFocus: hasFocus, expectsKeyboardInput: false)
        )
        await fulfillment(of: [discarded], timeout: 1)
        fixture.service.onFocusResponseDiscarded = nil
    }

    @MainActor
    private func respondToFocusSnapshot(
        hasFocusNodes: Bool,
        focusState: StateMachine.FocusState = .init(
            hasFocus: false,
            expectsKeyboardInput: false
        ),
        in fixture: FocusControllerFixture
    ) async {
        let availabilityRequested = expectation(description: "availability requested")
        let focusabilityChanged = expectation(description: "focusability changed")
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            if isFocusable == hasFocusNodes {
                focusabilityChanged.fulfill()
            }
        }
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.service] handle, requestID in
            availabilityRequested.fulfill()
            service?.onHasFocusNodesReceived(
                handle,
                requestID: requestID,
                hasFocusNodes: hasFocusNodes
            )
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            service?.onFocusStateReceived(
                handle,
                requestID: requestID,
                focusState: CommandQueueFocusState(
                    hasFocus: focusState.hasFocus,
                    expectsKeyboardInput: focusState.expectsKeyboardInput
                )
            )
        }

        fixture.controller.didAdvance()
        await fulfillment(of: [availabilityRequested, focusabilityChanged], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil

        fixture.commandQueue.stubRequestHasFocusNodes { _, _ in }
        fixture.commandQueue.stubRequestFocusState { _, _ in }
        XCTAssertEqual(fixture.controller.focusState, hasFocusNodes ? focusState : nil)
        XCTAssertEqual(fixture.focusSystem.isFocusable, hasFocusNodes)
    }

    @MainActor
    private func respondToFocusState(
        _ focusState: StateMachine.FocusState,
        in fixture: FocusControllerFixture
    ) async {
        let requested = expectation(description: "focus state requested")
        let applied = expectation(description: "focus state applied")
        fixture.controller.onFocusStateApplied = { appliedFocusState in
            if appliedFocusState == focusState {
                applied.fulfill()
            }
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.service] handle, requestID in
            requested.fulfill()
            service?.onFocusStateReceived(
                handle,
                requestID: requestID,
                focusState: CommandQueueFocusState(
                    hasFocus: focusState.hasFocus,
                    expectsKeyboardInput: focusState.expectsKeyboardInput
                )
            )
        }

        fixture.controller.didAdvance()
        await fulfillment(of: [requested, applied], timeout: 1)
        fixture.controller.onFocusStateApplied = nil
        fixture.commandQueue.stubRequestFocusState { _, _ in }
    }

    @MainActor
    private func makeFixture(
        systemIsFocusable: Bool = false,
        hasNativeFocus: Bool = false,
        defaultEntryDirection: FocusTraversalDirection? = nil
    ) -> FocusControllerFixture {
        FocusControllerFixture(
            systemIsFocusable: systemIsFocusable,
            hasNativeFocus: hasNativeFocus,
            defaultEntryDirection: defaultEntryDirection
        )
    }

    @MainActor
    func test_nativeEntry_reportsWhetherSequentialTraversalConsumedEntry() async {
        let results = [
            (moved: true, hasFocus: true, consumed: true),
            (moved: false, hasFocus: true, consumed: true),
            (moved: false, hasFocus: false, consumed: false),
            (moved: true, hasFocus: false, consumed: true)
        ]
        for direction: FocusTraversalDirection in [.next, .previous] {
            for result in results {
                let fixture = makeFixture()
                defer { fixture.controller.invalidate() }
                await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
                let traversal = CommandQueueFocusTraversalResult(
                    moved: result.moved,
                    focusState: .init(hasFocus: result.hasFocus, expectsKeyboardInput: false)
                )
                fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in traversal }
                fixture.commandQueue.stubFocusPreviousWithResultSynchronized { _ in traversal }

                XCTAssertEqual(
                    fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction),
                    result.consumed
                )
                XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, direction == .next ? 1 : 0)
                XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, direction == .previous ? 1 : 0)
                XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
                XCTAssertEqual(fixture.delegate.wakeCallCount, 1)
            }
        }
    }

    @MainActor
    func test_nativeEntry_preservesNodeConfirmedBySnapshotOrTraversal() async {
        for direction: FocusTraversalDirection? in [.next, .previous, nil] {
            for acquiredByTraversal in [false, true] {
                let fixture = makeFixture()
                defer { fixture.controller.invalidate() }
                await respondToFocusSnapshot(hasFocusNodes: true, focusState: .init(
                    hasFocus: !acquiredByTraversal, expectsKeyboardInput: false
                ), in: fixture)
                fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
                    .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
                }
                if acquiredByTraversal { _ = fixture.controller.traverse(.next) }
                XCTAssertTrue(fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction))
                XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, acquiredByTraversal ? 1 : 0)
                XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            }
        }
    }

    @MainActor
    func test_nativeEntry_traversesAfterSnapshotReportsRelease() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(
            hasFocusNodes: true,
            focusState: .init(hasFocus: true, expectsKeyboardInput: false),
            in: fixture
        )
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        await respondToFocusState(.init(hasFocus: false, expectsKeyboardInput: false), in: fixture)
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)

        XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
    }

    @MainActor
    func test_nativeEntry_preservesNodeAcquiredByDirectionalTraversal() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.commandQueue.stubFocusInDirectionSynchronized { _ in true }
        XCTAssertTrue(fixture.controller.focusInDirection(.right))
        fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_nativeEntry_doesNotTraverseWhileUnavailablePausedOrInvalidated() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        XCTAssertTrue(fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next))
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        fixture.controller.isPaused = true
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next))
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)

        fixture.controller.invalidate()
        fixture.controller.isPaused = false
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        fixture.focusSystem.isFocusable = true
        XCTAssertTrue(fixture.controller.focusSystem(fixture.focusSystem, didEnter: .next))
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_nativeEntry_traversesWhenEmptyAndReentersAfterExit() async {
        for direction: FocusTraversalDirection in [.next, .previous] {
            let fixture = makeFixture()
            defer { fixture.controller.invalidate() }
            await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
            fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
                .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
            }
            fixture.commandQueue.stubFocusPreviousWithResultSynchronized { _ in
                .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
            }
            fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction)
            fixture.controller.focusSystemDidExit(fixture.focusSystem)
            fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction)
            XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, direction == .next ? 2 : 0)
            XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, direction == .previous ? 2 : 0)
            XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
        }
    }

    @MainActor
    func test_nativeEntry_ignoresMissingDirectionAndForeignSystem() async {
        let fixture = makeFixture()
        defer { fixture.controller.invalidate() }
        await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
        XCTAssertTrue(fixture.controller.focusSystem(fixture.focusSystem, didEnter: nil))
        XCTAssertTrue(fixture.controller.focusSystem(MockFocusSystem(), didEnter: .next))
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_traversal_retainedNodeConsumesInputAndUpdatesFocusState() async {
        for direction: FocusTraversalDirection in [.next, .previous] {
            let fixture = makeFixture()
            defer { fixture.controller.invalidate() }
            await respondToFocusSnapshot(hasFocusNodes: true, in: fixture)
            let retained = CommandQueueFocusTraversalResult(moved: false, focusState: .init(
                hasFocus: true, expectsKeyboardInput: true
            ))
            fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in retained }
            fixture.commandQueue.stubFocusPreviousWithResultSynchronized { _ in retained }
            XCTAssertTrue(fixture.controller.traverse(direction))
            XCTAssertEqual(fixture.controller.focusState, .init(hasFocus: true, expectsKeyboardInput: true))
            XCTAssertEqual(fixture.delegate.wakeCallCount, 1)

            fixture.controller.focusSystem(fixture.focusSystem, didEnter: direction)
            XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, direction == .next ? 1 : 0)
            XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, direction == .previous ? 1 : 0)
        }
    }
}

@MainActor
private final class FocusControllerFixture {
    let commandQueue: MockCommandQueue
    let service: StateMachineService
    let stateMachine: StateMachine
    let focusSystem: MockFocusSystem
    let delegate: MockFocusControllerDelegate
    let controller: FocusController

    init(systemIsFocusable: Bool, hasNativeFocus: Bool, defaultEntryDirection: FocusTraversalDirection?) {
        let commandQueue = MockCommandQueue()
        let service = StateMachineService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: service),
            stateMachineHandle: 123
        )
        let focusSystem = MockFocusSystem()
        let delegate = MockFocusControllerDelegate()
        focusSystem.isFocusable = systemIsFocusable
        focusSystem.defaultEntryDirection = defaultEntryDirection
        let controller = FocusController(
            dependencies: .init(
                stateMachine: stateMachine,
                focusSystem: focusSystem
            ),
            hasNativeFocus: hasNativeFocus
        )
        controller.delegate = delegate

        self.commandQueue = commandQueue
        self.service = service
        self.stateMachine = stateMachine
        self.focusSystem = focusSystem
        self.delegate = delegate
        self.controller = controller

        commandQueue.stubDeleteStateMachine { [weak commandQueue, weak service] handle in
            guard let requestID = commandQueue?.deleteStateMachineCalls.last?.requestID else { return }
            service?.onStateMachineDeleted(handle, requestID: requestID)
        }
    }
}

@MainActor
private final class MockFocusControllerDelegate: FocusControllerDelegate {
    private(set) var wakeCallCount = 0

    func focusControllerDidRequestWake(_ controller: FocusController) {
        wakeCallCount += 1
    }
}
