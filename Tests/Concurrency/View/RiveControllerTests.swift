//
//  RiveControllerTests.swift
//  RiveRuntimeTests
//
//  Created by Cursor Assistant on 2/20/26.
//

import XCTest
import UIKit
@preconcurrency @testable import RiveRuntime

final class RiveControllerTests: XCTestCase {
    @MainActor
    func test_advance_updatesFocusability() async throws {
        let fixture = try await makeController(dataBind: .none)
        defer { fixture.controller.invalidate() }
        let updated = expectation(description: "focusability updated")
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            guard isFocusable else { return }
            updated.fulfill()
        }
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: false, expectsKeyboardInput: false
            ))
        }

        _ = fixture.controller.advance(
            now: 0,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 100),
            scaleProvider: MockScaleProvider()
        )

        await fulfillment(of: [updated], timeout: 1)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
    }

    @MainActor
    func test_isPaused_preservesOnlyNativeFocusPresentAtAttachment() async throws {
        for hasNativeFocus in [false, true] {
            let fixture = try await makeController(hasNativeFocus: hasNativeFocus)
            defer { fixture.controller.invalidate() }
            XCTAssertFalse(fixture.focusSystem.isFocusable)
            let updated = expectation(description: "focusability updated")
            fixture.focusSystem.onIsFocusableChanged = { isFocusable in
                guard isFocusable else { return }
                updated.fulfill()
            }
            fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
                service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
            }
            fixture.commandQueue.stubRequestFocusState { [weak service = fixture.stateMachineService] handle, requestID in
                service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                    hasFocus: false, expectsKeyboardInput: false
                ))
            }
            _ = fixture.controller.advance(
                now: 0,
                isOnscreen: true,
                drawableSize: CGSize(width: 100, height: 100),
                scaleProvider: MockScaleProvider()
            )
            await fulfillment(of: [updated], timeout: 1)

            // A replacement may already own native focus without a new entry callback.
            fixture.controller.isPaused = true

            XCTAssertEqual(fixture.focusSystem.isFocusable, hasNativeFocus)
            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        }
    }

    @MainActor
    func test_invalidate_invalidatesFocusSystem() async throws {
        let fixture = try await makeController(dataBind: .none)

        fixture.controller.invalidate()
        fixture.controller.invalidate()

        XCTAssertNil(fixture.focusSystem.delegate)
        XCTAssertEqual(fixture.focusSystem.invalidateCallCount, 1)
        XCTAssertEqual(fixture.commandQueue.clearFocusCalls.count, 1)
    }

    @MainActor
    func test_deinit_clearsFocusOnRetainedStateMachineAndInvalidatesFocusSystem() async throws {
        var fixture: ControllerFixture? = try await makeController(dataBind: .none)
        let stateMachine = try XCTUnwrap(fixture?.stateMachine)
        let commandQueue = try XCTUnwrap(fixture?.commandQueue)
        let focusSystem = try XCTUnwrap(fixture?.focusSystem)
        weak var controller = fixture?.controller
        focusSystem.isFocusable = true
        commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }
        XCTAssertEqual(fixture?.controller.handleKeyInput(
            .tab, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true
        ), true)
        let focusedMachineHandle = try XCTUnwrap(commandQueue.focusNextWithResultSynchronizedCalls.last).stateMachineHandle
        let cleared = expectation(description: "retained state machine focus cleared")
        commandQueue.stubClearFocus { handle, _ in
            XCTAssertEqual(handle, focusedMachineHandle)
            cleared.fulfill()
        }

        fixture = nil

        XCTAssertNil(controller)
        await fulfillment(of: [cleared], timeout: 1)
        withExtendedLifetime(stateMachine) {
            XCTAssertFalse(focusSystem.isFocusable)
            XCTAssertNil(focusSystem.delegate)
            XCTAssertEqual(focusSystem.invalidateCallCount, 1)
            XCTAssertEqual(commandQueue.clearFocusCalls.count, 1)
        }
    }

    @MainActor
    func test_focusTraversal_unsettlesController() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)
        fixture.focusSystem.isFocusable = true
        fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }
        let unsettled = expectation(description: "controller unsettled")
        fixture.controller.onIsSettledChangedForTesting = { isSettled in
            guard !isSettled else { return }
            unsettled.fulfill()
        }

        XCTAssertTrue(fixture.controller.handleKeyInput(
            .tab, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true
        ))

        await fulfillment(of: [unsettled], timeout: 1)
        XCTAssertFalse(fixture.controller.isSettled)
    }

    @MainActor
    func test_init_startsUnsettled() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectIsSettled(false, within: fixture)
    }

    @MainActor
    func test_stateMachineSettled_setsIsSettledTrue() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)
    }

    @MainActor
    func test_fitChange_setsIsSettledFalse() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        await expectIsSettled(false, within: fixture) {
            fixture.rive.fit = .cover(alignment: .center)
        }
    }

    @MainActor
    func test_fitChangedToLayoutWithExplicitScale_setsArtboardSizeWithScale() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        await expectIsSettled(false, within: fixture) {
            fixture.rive.fit = .layout(scaleFactor: .explicit(2))
        }

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 320)
        XCTAssertEqual(call.height, 240)
        XCTAssertEqual(call.scale, 2)
    }

    @MainActor
    func test_fitChangedToLayoutWithAutomaticScale_setsArtboardSizeUsingScaleProvider() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            delegate: MockControllerDelegate(nativeScale: 3, displayScale: 1)
        )
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        await expectIsSettled(false, within: fixture) {
            fixture.rive.fit = .layout(scaleFactor: .automatic)
        }

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 320)
        XCTAssertEqual(call.height, 240)
        XCTAssertEqual(call.scale, 3)
    }

    @MainActor
    func test_fitChangedToLayout_withZeroDrawableSize_fallsBackToZeroSize() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            delegate: MockControllerDelegate(drawableSize: .zero)
        )
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        await expectIsSettled(false, within: fixture) {
            fixture.rive.fit = .layout(scaleFactor: .explicit(1))
        }

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 0)
        XCTAssertEqual(call.height, 0)
    }

    @MainActor
    func test_fitChangedToLayout_withNoNativeScale_fallsBackToUnitScale() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            delegate: MockControllerDelegate(nativeScale: nil, displayScale: 1)
        )
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        await expectIsSettled(false, within: fixture) {
            fixture.rive.fit = .layout(scaleFactor: .automatic)
        }

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.scale, 1)
    }

    @MainActor
    func test_backgroundColorChange_setsIsSettledFalse() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        await expectIsSettled(false, within: fixture) {
            fixture.rive.backgroundColor = Color(red: 255, green: 0, blue: 0, alpha: 255)
        }
    }

    @MainActor
    func test_dirtyEvent_setsIsSettledFalse() async throws {
        let fixture = try await makeController(dataBind: .auto)
        await expectSettled(within: fixture)

        await expectIsSettled(false, within: fixture) {
            fixture.viewModelInstance?.setValue(of: StringProperty(path: "path/to/property"), to: "new value")
        }
    }

    @MainActor
    func test_init_observesUniqueBoundViewModelInstances() async throws {
        let fixture = try await makeController(dataBind: .none) { stateMachine, commandQueue in
            let shared = self.makeViewModelInstance(handle: 1, commandQueue: commandQueue)
            let theme = self.makeViewModelInstance(handle: 2, commandQueue: commandQueue)
            try await stateMachine.bindViewModelInstances(main: shared) {
                ("Shared", shared)
                ("Theme", theme)
            }
        }

        XCTAssertEqual(fixture.controller.dirtyObservationHandlesForTesting, Set([1, 2]))
    }

    @MainActor
    func test_bindViewModelInstances_observesGlobalAndMarksDirty() async throws {
        let fixture = try await makeController(dataBind: .none)
        let theme = makeViewModelInstance(handle: 1, commandQueue: fixture.commandQueue)
        await expectSettled(within: fixture)

        await expectIsSettled(false, within: fixture) {
            try! await fixture.stateMachine.bindViewModelInstances {
                ("Theme", theme)
            }
        }

        XCTAssertEqual(fixture.controller.dirtyObservationHandlesForTesting, Set([1]))

        await expectSettledAfterDirty(within: fixture)
        await expectIsSettled(false, within: fixture) {
            theme.setValue(of: StringProperty(path: "value"), to: "updated")
        }
    }

    @MainActor
    func test_replacingViewModelInstance_updatesDirtyObservation() async throws {
        let fixture = try await makeController(dataBind: .none)
        let first = makeViewModelInstance(handle: 1, commandQueue: fixture.commandQueue)
        let second = makeViewModelInstance(handle: 2, commandQueue: fixture.commandQueue)

        try await fixture.stateMachine.bindViewModelInstances {
            ("Theme", first)
        }
        await expectSettledAfterDirty(within: fixture)

        var started: [UInt64] = []
        var cancelled: [UInt64] = []
        fixture.controller.onDirtyObservationStartedForTesting = { started.append($0) }
        fixture.controller.onDirtyObservationCancelledForTesting = { cancelled.append($0) }

        try await fixture.stateMachine.bindViewModelInstances {
            ("Theme", second)
        }

        XCTAssertEqual(started, [2])
        XCTAssertEqual(cancelled, [1])
        XCTAssertEqual(fixture.controller.dirtyObservationHandlesForTesting, Set([2]))

        await expectSettledAfterDirty(within: fixture)
        first.setValue(of: StringProperty(path: "value"), to: "old")
        await Task.yield()
        await Task.yield()
        XCTAssertTrue(fixture.controller.isSettled)

        await expectIsSettled(false, within: fixture) {
            second.setValue(of: StringProperty(path: "value"), to: "new")
        }
    }

    @MainActor
    func test_swappingViewModelInstanceBindings_preservesDirtyObservations() async throws {
        let fixture = try await makeController(dataBind: .none)
        let first = makeViewModelInstance(handle: 1, commandQueue: fixture.commandQueue)
        let second = makeViewModelInstance(handle: 2, commandQueue: fixture.commandQueue)

        try await fixture.stateMachine.bindViewModelInstances(main: first) {
            ("First", first)
            ("Second", second)
        }

        var started: [UInt64] = []
        var cancelled: [UInt64] = []
        fixture.controller.onDirtyObservationStartedForTesting = { started.append($0) }
        fixture.controller.onDirtyObservationCancelledForTesting = { cancelled.append($0) }

        try await fixture.stateMachine.bindViewModelInstances {
            ("First", second)
            ("Second", first)
        }

        XCTAssertTrue(started.isEmpty)
        XCTAssertTrue(cancelled.isEmpty)
        XCTAssertEqual(fixture.controller.dirtyObservationHandlesForTesting, Set([1, 2]))
    }

    @MainActor
    func test_deinit_cancelsAllDirtyObservations() async throws {
        var fixture: ControllerFixture? = try await makeController(dataBind: .none) { stateMachine, commandQueue in
            let main = self.makeViewModelInstance(handle: 1, commandQueue: commandQueue)
            let theme = self.makeViewModelInstance(handle: 2, commandQueue: commandQueue)
            try await stateMachine.bindViewModelInstances(main: main) {
                ("Theme", theme)
            }
        }
        var cancelled = Set<UInt64>()
        fixture?.controller.onDirtyObservationCancelledForTesting = { cancelled.insert($0) }
        weak let controller = fixture?.controller

        fixture = nil

        XCTAssertNil(controller)
        XCTAssertEqual(cancelled, Set([1, 2]))
    }

    @MainActor
    func test_handleInput_setsIsSettledFalse() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        let event = PointerEvent(
            id: "touch-test",
            position: CGPoint(x: 10, y: 20),
            bounds: CGSize(width: 100, height: 200),
            fit: .contain,
            alignment: .center,
            scaleFactor: 1
        )
        await expectIsSettled(false, within: fixture) {
            fixture.controller.handleInput(.pointerDown(event))
        }
    }

    @MainActor
    func test_advance_whenSettledAndFirstDraw_returnsConfiguration_andAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        let configuration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(configuration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_whenSettledAfterFirstDraw_skipsSecondFrame_andOnlyFirstFrameAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNil(secondConfiguration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_globalAssetChange_whenSettled_producesAnotherFrame() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)
        let drawableSize = CGSize(width: 100, height: 200)

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: drawableSize,
            scaleProvider: MockScaleProvider()
        )
        let unchangedConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: drawableSize,
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNil(unchangedConfiguration)

        await expectIsSettled(false, within: fixture) {
            fixture.rive.file.worker.globalAssetsDidChange.send()
        }

        let changedConfiguration = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: drawableSize,
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(changedConfiguration)
    }

    @MainActor
    func test_advance_whenSettledAndTransitionsOffscreenToOnscreen_returnsConfiguration_andDoesNotAdvance() async throws {
        let fixture = try await makeController(dataBind: .none)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        await expectSettled(within: fixture)

        let configuration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(configuration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_whenSettledAndDrawableSizeChanges_returnsConfiguration_andDoesNotAdvance() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNotNil(secondConfiguration)
        XCTAssertEqual(secondConfiguration?.size, CGSize(width: 300, height: 400))
        // Only the bootstrap frame advances the state machine; the resize-triggered
        // draw must not advance (settled views do not animate).
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_whenSettledAndDrawableSizeUnchangedAfterResize_skipsFrame() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )
        let thirdConfiguration = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNil(thirdConfiguration)
    }

    @MainActor
    func test_advance_whenSettledLayoutResizes_appliesNewArtboardSizeWithoutAdvancingTime() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            fit: .layout(scaleFactor: .explicit(1))
        )
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let baseline = fixture.commandQueue.setArtboardSizeCalls.count
        let baselineAdvances = fixture.commandQueue.advanceStateMachineCalls.count
        fixture.commandQueue.stubAdvanceStateMachine { [weak commandQueue = fixture.commandQueue] _, _, _ in
            // The new size must already be queued when the layout is applied.
            XCTAssertEqual(commandQueue?.setArtboardSizeCalls.last?.width, 300)
            XCTAssertEqual(commandQueue?.setArtboardSizeCalls.last?.height, 400)
        }

        let resized = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )
        let unchanged = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(resized?.size, CGSize(width: 300, height: 400))
        XCTAssertNil(unchanged)
        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 300)
        XCTAssertEqual(call.height, 400)
        XCTAssertEqual(call.scale, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, baselineAdvances + 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.last?.time, 0)
    }

    @MainActor
    func test_advance_whenPausedSettledLayoutResizes_appliesLayoutWithoutAdvancingTime() async throws {
        let fixture = try await makeController(fit: .layout(scaleFactor: .explicit(1)))
        await expectSettled(within: fixture)
        fixture.controller.isPaused = true

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let baselineAdvances = fixture.commandQueue.advanceStateMachineCalls.count

        let resized = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(resized?.size, CGSize(width: 300, height: 400))
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, baselineAdvances + 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.last?.time, 0)
    }

    @MainActor
    func test_advance_whenLayoutFitWithExplicitScale_reappliesArtboardSizeWithScale() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            fit: .layout(scaleFactor: .explicit(2))
        )
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 300)
        XCTAssertEqual(call.height, 400)
        XCTAssertEqual(call.scale, 2)
    }

    @MainActor
    func test_advance_whenLayoutFitWithAutomaticScale_usesScaleProvider() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            fit: .layout(scaleFactor: .automatic)
        )
        await expectSettled(within: fixture)

        let scaleProvider = MockScaleProvider(nativeScale: 3, displayScale: 1)
        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: scaleProvider
        )
        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: scaleProvider
        )

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 300)
        XCTAssertEqual(call.height, 400)
        XCTAssertEqual(call.scale, 3)
    }

    @MainActor
    func test_advance_whenNonLayoutFitAndDrawableSizeChanges_doesNotReapplyArtboardSize() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let baseline = fixture.commandQueue.setArtboardSizeCalls.count

        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline)
    }

    @MainActor
    func test_advance_whenSettledAndOffscreenAndDrawableSizeChanges_skipsDraw() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        let configuration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        // Offscreen views must not draw after the first frame, even if the
        // drawable size changed — the redraw-on-resize allowance only applies
        // when the view is visible.
        XCTAssertNil(configuration)
    }

    @MainActor
    func test_advance_whenSettledAndBecameOnscreenAndDrawableSizeChanges_returnsConfiguration() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let returningConfiguration = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        // Settled views should still redraw when returning onscreen, with the
        // new drawable size reflected in the configuration.
        XCTAssertNotNil(returningConfiguration)
        XCTAssertEqual(returningConfiguration?.size, CGSize(width: 300, height: 400))
    }

    @MainActor
    func test_advance_firstFrame_withLayoutFit_setsArtboardSize() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            fit: .layout(scaleFactor: .explicit(2))
        )
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count
        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline + 1)
        let call = try XCTUnwrap(fixture.commandQueue.setArtboardSizeCalls.last)
        XCTAssertEqual(call.width, 100)
        XCTAssertEqual(call.height, 200)
        XCTAssertEqual(call.scale, 2)
    }

    @MainActor
    func test_advance_firstFrame_withNonLayoutFit_doesNotSetArtboardSize() async throws {
        let fixture = try await makeController(
            dataBind: .none,
            fit: .contain(alignment: .center)
        )
        await expectSettled(within: fixture)

        let baseline = fixture.commandQueue.setArtboardSizeCalls.count
        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.setArtboardSizeCalls.count, baseline)
    }

    @MainActor
    func test_advance_whenUnsettledAndOffscreenFirstFrame_returnsConfiguration_andAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)

        let configuration = fixture.controller.advance(
            now: 10,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(configuration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_whenUnsettledAndOffscreenConsecutiveFrames_skipsSecondDraw_andStillAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNil(secondConfiguration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0.5, accuracy: 0.0001)
    }

    @MainActor
    func test_advance_whenUnsettledAndTransitionsOnscreenToOffscreen_skipsDrawAfterFirstFrame_andStillAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNil(secondConfiguration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0.5, accuracy: 0.0001)
    }

    @MainActor
    func test_advance_whenUnsettledAndOnscreen_returnsConfiguration_andAdvances() async throws {
        let fixture = try await makeController(dataBind: .none)

        let configuration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(configuration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_secondCall_usesTimestampDelta() async throws {
        let fixture = try await makeController(dataBind: .none)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0.5, accuracy: 0.0001)
    }

    @MainActor
    func test_advance_whenTimestampDecreases_clampsDeltaToZero() async throws {
        let fixture = try await makeController(dataBind: .none)

        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        _ = fixture.controller.advance(
            now: 10.499,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0)
    }

    @MainActor
    func test_advance_whenPaused_allowsFirstDraw_thenBlocksSubsequentDraws() async throws {
        let fixture = try await makeController(dataBind: .none)
        fixture.controller.isPaused = true

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNil(secondConfiguration)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_advance_whenPausedAndDrawableSizeChanges_returnsConfiguration_andDoesNotAdvance() async throws {
        let fixture = try await makeController(dataBind: .none)
        await expectSettled(within: fixture)
        fixture.controller.isPaused = true

        let firstConfiguration = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        let secondConfiguration = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 300, height: 400),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertNotNil(firstConfiguration)
        XCTAssertNotNil(secondConfiguration)
        XCTAssertEqual(secondConfiguration?.size, CGSize(width: 300, height: 400))
        // Paused + settled views do not advance time; the resize-triggered draw
        // is bootstrap-only (delta 0) and produces no additional advance.
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
    }

    @MainActor
    func test_resumeAfterSettling_advancesAndRefreshesFocus() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: false, expectsKeyboardInput: false
            ))
        }
        let initiallyFocusable = expectation(description: "initial focus eligibility")
        fixture.focusSystem.onIsFocusableChanged = { if $0 { initiallyFocusable.fulfill() } }
        _ = fixture.controller.advance(
            now: 0, isOnscreen: true,
            drawableSize: fixture.delegate.drawableSize, scaleProvider: fixture.delegate
        )
        await fulfillment(of: [initiallyFocusable], timeout: 1)
        fixture.focusSystem.onIsFocusableChanged = nil
        await expectSettled(within: fixture)

        fixture.controller.isPaused = true
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        let advancesBeforeResume = fixture.commandQueue.advanceStateMachineCalls.count
        let availabilityBeforeResume = fixture.commandQueue.requestHasFocusNodesCalls.count
        let snapshotsBeforeResume = fixture.commandQueue.requestFocusStateCalls.count
        let availabilityRequested = expectation(description: "fresh availability requested after resume")
        let stateRequested = expectation(description: "fresh focus state requested after resume")
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
            availabilityRequested.fulfill()
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.stateMachineService] handle, requestID in
            stateRequested.fulfill()
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: false, expectsKeyboardInput: false
            ))
        }

        fixture.controller.isPaused = false
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        _ = fixture.controller.advance(
            now: 10, isOnscreen: true,
            drawableSize: fixture.delegate.drawableSize, scaleProvider: fixture.delegate
        )
        await fulfillment(of: [availabilityRequested, stateRequested], timeout: 1)

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, advancesBeforeResume + 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.last?.time, 0)
        XCTAssertEqual(fixture.commandQueue.requestHasFocusNodesCalls.count, availabilityBeforeResume + 1)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, snapshotsBeforeResume + 1)
        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_advance_whenResumedAfterPausedBlock_usesZeroDeltaFirstFrame_withoutResetTiming() async throws {
        let fixture = try await makeController(dataBind: .none)
        fixture.controller.isPaused = true

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        fixture.controller.isPaused = false
        _ = fixture.controller.advance(
            now: 11,
            isOnscreen: false,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0)
    }

    @MainActor
    func test_advance_whenResumedAfterPauseTransition_usesZeroDeltaEvenIfTimestampWasSet() async throws {
        let fixture = try await makeController(dataBind: .none)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        fixture.controller.isPaused = true
        _ = fixture.controller.advance(
            now: 20,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        fixture.controller.isPaused = false
        _ = fixture.controller.advance(
            now: 30,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0)
    }

    @MainActor
    func test_settingIsPausedTrue_resetsTimingForNextUnpausedAdvance() async throws {
        let fixture = try await makeController(dataBind: .none)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        fixture.controller.isPaused = true
        fixture.controller.isPaused = false

        _ = fixture.controller.advance(
            now: 30,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[0].time, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls[1].time, 0)
    }

    // MARK: - Semantics Lifecycle

    #if !os(macOS) || RIVE_MAC_CATALYST

    @MainActor
    func test_init_voiceOverAlreadyOn_startsSemanticsImmediately() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()

        XCTAssertNotNil(fixture.controller.semanticsController.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 1)
    }

    @MainActor
    func test_init_voiceOverOff_doesNotStartSemantics() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = false

        let fixture = try await makeControllerWithSemantics()

        XCTAssertNil(fixture.controller.semanticsController.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 0)
    }

    @MainActor
    func test_voiceOverNotification_turnsOn_startsSemanticsManager() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = false

        let fixture = try await makeControllerWithSemantics()
        XCTAssertNil(fixture.controller.semanticsController.manager)

        MockUIAccessibility.isVoiceOverRunning = true
        fixture.mockNotificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNotNil(fixture.controller.semanticsController.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 1)
    }

    @MainActor
    func test_voiceOverNotification_turnsOn_whileSettled_unsettlesForDrain() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = false

        let fixture = try await makeControllerWithSemantics()

        // Bootstrap draw + settle
        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )
        await expectSettled(within: fixture)
        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, 0)

        // Enable VoiceOver while settled
        MockUIAccessibility.isVoiceOverRunning = true
        fixture.mockNotificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertFalse(fixture.controller.isSettled)

        // Next advance should enter shouldAdvance and drain
        _ = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, 2)
    }

    @MainActor
    func test_voiceOverNotification_turnsOff_stopsSemanticsManager() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        XCTAssertNotNil(fixture.controller.semanticsController.manager)

        MockUIAccessibility.isVoiceOverRunning = false
        fixture.mockNotificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNil(fixture.controller.semanticsController.manager)
    }

    @MainActor
    func test_advance_whenSemanticsActive_callsDrainSemanticsDiff() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        let drainCountAfterSetup = fixture.commandQueue.drainSemanticsDiffCalls.count

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, drainCountAfterSetup + 1)
    }

    @MainActor
    func test_advance_whenSemanticsInactive_doesNotCallDrainSemanticsDiff() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = false

        let fixture = try await makeControllerWithSemantics()

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, 0)
    }

    @MainActor
    func test_advance_drainSemanticsDiff_passesDrawableSize() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 960, height: 720),
            scaleProvider: MockScaleProvider()
        )

        let call = fixture.commandQueue.drainSemanticsDiffCalls.last
        XCTAssertNotNil(call)
        XCTAssertEqual(call?.viewBounds, CGSize(width: 960, height: 720))
    }

    @MainActor
    func test_semanticsDiffStream_appliesDiffToManager() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()

        let diffProcessed = expectation(description: "diff processed")
        fixture.controller.semanticsController.onSemanticsDiffProcessedForTesting = {
            diffProcessed.fulfill()
        }

        let textNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Hello", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50,
            parentID: -1, siblingIndex: 0
        )
        let diff = SemanticsDiff(
            frameNumber: 1, treeVersion: 1, rootID: 1,
            removed: [], added: [textNode], moved: [],
            childrenUpdated: [], updatedSemantic: [], updatedGeometry: []
        )

        fixture.stateMachineService.onSemanticsDiffReceived(
            fixture.stateMachine.stateMachineHandle,
            requestID: 1,
            diff: diff
        )
        await fulfillment(of: [diffProcessed], timeout: 1.0)

        fixture.controller.semanticsController.manager?.commitDiffs()

        let elements = fixture.controller.semanticsController.manager?.accessibilityElements
        XCTAssertEqual(elements?.count, 1)
        XCTAssertEqual(elements?.first?.accessibilityLabel, "Hello")
    }

    @MainActor
    func test_semanticsDiffStream_postsLayoutChangedNotification() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()

        let diffProcessed = expectation(description: "diff processed")
        fixture.controller.semanticsController.onSemanticsDiffProcessedForTesting = {
            diffProcessed.fulfill()
        }

        let diff = SemanticsDiff(
            frameNumber: 1, treeVersion: 1, rootID: 1,
            removed: [], added: [SemanticsDiffNode(
                id: 1, role: .text, label: "Hello", value: "", hint: "",
                stateFlags: [], traitFlags: [], headingLevel: 0,
                minX: 0, minY: 0, maxX: 100, maxY: 50,
                parentID: -1, siblingIndex: 0
            )], moved: [],
            childrenUpdated: [], updatedSemantic: [], updatedGeometry: []
        )

        fixture.stateMachineService.onSemanticsDiffReceived(
            fixture.stateMachine.stateMachineHandle,
            requestID: 1,
            diff: diff
        )
        await fulfillment(of: [diffProcessed], timeout: 1.0)

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semanticsController.manager?.commitDiffs()

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    @MainActor
    func test_advance_whenSettled_stillCommitsDiffsAndProcessesMessages() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()

        // Bootstrap draw
        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        // Settle
        await expectSettled(within: fixture)

        // Enqueue a diff while settled
        let textNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Settled Text", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50,
            parentID: -1, siblingIndex: 0
        )
        let diff = SemanticsDiff(
            frameNumber: 2, treeVersion: 2, rootID: 1,
            removed: [], added: [textNode], moved: [],
            childrenUpdated: [], updatedSemantic: [], updatedGeometry: []
        )
        fixture.controller.semanticsController.manager?.enqueue(diff: diff)
        MockUIAccessibility.postedNotifications = []

        // Advance while settled — commitDiffs should still run
        _ = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 640, height: 480),
            scaleProvider: MockScaleProvider()
        )

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)

        let elements = fixture.controller.semanticsController.manager?.accessibilityElements
        XCTAssertEqual(elements?.count, 1)
        XCTAssertEqual(elements?.first?.accessibilityLabel, "Settled Text")
    }

    @MainActor
    func test_managerDidCommitDiffs_postsLayoutChangedNotification() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        let manager = fixture.controller.semanticsController.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semanticsController.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    @MainActor
    func test_managerDidCommitDiffs_modalEnter_postsScreenChanged() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        let manager = fixture.controller.semanticsController.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semanticsController.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: true)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .screenChanged)
    }

    @MainActor
    func test_managerDidCommitDiffs_modalExit_postsScreenChanged() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        let manager = fixture.controller.semanticsController.manager!

        fixture.controller.semanticsController.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: true)

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semanticsController.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .screenChanged)
    }

    @MainActor
    func test_managerDidCommitDiffs_noModalTransition_postsLayoutChanged() async throws {
        MockUIAccessibility.reset()
        MockUIAccessibility.isVoiceOverRunning = true

        let fixture = try await makeControllerWithSemantics()
        let manager = fixture.controller.semanticsController.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semanticsController.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    #endif

    // MARK: - Settled/dirty race

    @MainActor
    func test_staleSettledAfterDirty_doesNotOverwriteDirty() async throws {
        let fixture = try await setupStaleSettledAfterDirty()
        XCTAssertFalse(fixture.controller.isSettled)
    }

    @MainActor
    func test_advanceAfterStaleSettled_producesFrame() async throws {
        let fixture = try await setupStaleSettledAfterDirty()
        let configuration = fixture.controller.advance(
            now: 11,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )
        XCTAssertNotNil(configuration)
    }

    // MARK: - Keyboard coordination

    @MainActor
    func test_keyPress_controllerReplacementPreservesNativeOwnershipWithoutReplayingInput() async throws {
        for handled in [false, true] {
            for cancelled in [false, true] {
                let original = try await makeController()
                let replacement = try await makeController()
                defer {
                    original.controller.invalidate()
                    replacement.controller.invalidate()
                }
                original.commandQueue.stubKeyInputSynchronized { _ in handled }
                replacement.commandQueue.stubKeyInputSynchronized { _ in !handled }
                let view = KeyboardTestMetalView(frame: .zero, device: nil)
                let press = MockKeyboardPress()
                view.controller = original.controller
                view.pressesBegan([press], with: nil)

                view.controller = nil
                view.controller = replacement.controller
                view.pressesChanged([press], with: nil)
                if cancelled {
                    view.pressesCancelled([press], with: nil)
                } else {
                    view.pressesEnded([press], with: nil)
                }

                XCTAssertEqual(original.commandQueue.keyInputSynchronizedCalls.count, 1)
                XCTAssertTrue(replacement.commandQueue.keyInputSynchronizedCalls.isEmpty)
                XCTAssertEqual(view.nativeResponder.calls, handled ? [] : [
                    .init(phase: .began, presses: [press]),
                    .init(phase: .changed, presses: [press]),
                    .init(phase: cancelled ? .cancelled : .ended, presses: [press])
                ])

                // A fresh press of the same key now belongs to the replacement.
                let nextPress = MockKeyboardPress()
                view.pressesBegan([nextPress], with: nil)
                view.pressesEnded([nextPress], with: nil)
                XCTAssertEqual(replacement.commandQueue.keyInputSynchronizedCalls, [
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
                ])
            }
        }
    }

    @MainActor
    func test_keyPress_lateReleaseAfterControllerReplacementDoesNotEndFreshPress() async throws {
        for handled in [false, true] {
            for cancelled in [false, true] {
                let original = try await makeController()
                let replacement = try await makeController()
                defer {
                    original.controller.invalidate()
                    replacement.controller.invalidate()
                }
                original.commandQueue.stubKeyInputSynchronized { _ in handled }
                replacement.commandQueue.stubKeyInputSynchronized { _ in !handled }
                let view = KeyboardTestMetalView(frame: .zero, device: nil)
                let oldPress = MockKeyboardPress()
                let newPress = MockKeyboardPress()
                view.controller = original.controller
                view.pressesBegan([oldPress], with: nil)

                view.controller = replacement.controller
                view.pressesBegan([newPress], with: nil)
                view.pressesChanged([oldPress], with: nil)
                if cancelled {
                    view.pressesCancelled([oldPress], with: nil)
                } else {
                    view.pressesEnded([oldPress], with: nil)
                }

                // The old press cannot release the new controller's same-key press.
                XCTAssertEqual(replacement.commandQueue.keyInputSynchronizedCalls, [
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false)
                ])
                let nativeCalls: [MockKeyboardResponder.Call] = handled ? [
                    .init(phase: .began, presses: [newPress])
                ] : [
                    .init(phase: .began, presses: [oldPress]),
                    .init(phase: .changed, presses: [oldPress]),
                    .init(phase: cancelled ? .cancelled : .ended, presses: [oldPress])
                ]
                XCTAssertEqual(view.nativeResponder.calls, nativeCalls)

                // The new press still owns its own changes and release.
                view.pressesChanged([newPress], with: nil)
                view.pressesEnded([newPress], with: nil)
                XCTAssertEqual(original.commandQueue.keyInputSynchronizedCalls, [
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false)
                ])
                XCTAssertEqual(replacement.commandQueue.keyInputSynchronizedCalls, [
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                    .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
                ])
                XCTAssertEqual(view.nativeResponder.calls, nativeCalls + (handled ? [
                    .init(phase: .changed, presses: [newPress]),
                    .init(phase: .ended, presses: [newPress])
                ] : []))
            }
        }
    }

    @MainActor
    func test_keyPress_resetDoesNotResumePressWhenControllerReturns() async throws {
        for handled in [false, true] {
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            fixture.commandQueue.stubKeyInputSynchronized { _ in handled }
            let view = KeyboardTestMetalView(frame: .zero, device: nil)
            let press = MockKeyboardPress()
            view.controller = fixture.controller
            view.pressesBegan([press], with: nil)

            view.controller = nil
            view.controller = fixture.controller
            view.pressesEnded([press], with: nil)

            XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false)
            ])
            XCTAssertEqual(view.nativeResponder.calls, handled ? [] : [
                .init(phase: .began, presses: [press]),
                .init(phase: .ended, presses: [press])
            ])
        }
    }

    @MainActor
    func test_keyPress_assigningSameControllerPreservesActivePress() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        let view = KeyboardTestMetalView(frame: .zero, device: nil)
        let press = MockKeyboardPress()
        view.controller = fixture.controller
        view.pressesBegan([press], with: nil)

        view.controller = fixture.controller
        view.pressesEnded([press], with: nil)

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
            .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
            .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
        ])
        XCTAssertTrue(view.nativeResponder.calls.isEmpty)
    }

    @MainActor
    func test_keyPress_missedReleaseDoesNotRetainPress() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        let view = KeyboardTestMetalView(frame: .zero, device: nil)
        view.controller = fixture.controller
        weak var releasedPress: UIPress?

        autoreleasepool {
            let press = MockKeyboardPress()
            releasedPress = press
            view.pressesBegan([press], with: nil)
        }

        XCTAssertNil(releasedPress)
        XCTAssertTrue(view.nativeResponder.calls.isEmpty)
    }

    @MainActor
    func test_keyPress_changesDoNotRepeatInputOrChangeNativeOwnership() async throws {
        for handled in [false, true] {
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            let view = KeyboardTestMetalView(frame: .zero, device: nil)
            let press = MockKeyboardPress()
            view.controller = fixture.controller
            fixture.commandQueue.stubKeyInputSynchronized { _ in handled }
            view.pressesBegan([press], with: nil)

            fixture.commandQueue.stubKeyInputSynchronized { _ in !handled }
            view.pressesChanged([press], with: nil)
            view.pressesChanged([press], with: nil)
            view.pressesEnded([press], with: nil)

            XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
            ])
            XCTAssertEqual(view.nativeResponder.calls, handled ? [] : [
                .init(phase: .began, presses: [press]),
                .init(phase: .changed, presses: [press]),
                .init(phase: .changed, presses: [press]),
                .init(phase: .ended, presses: [press])
            ])
        }
    }

    @MainActor
    func test_keyPress_freshPressAfterMissedReleaseResetsNativeOwnership() async throws {
        for handled in [false, true] {
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            let view = KeyboardTestMetalView(frame: .zero, device: nil)
            let previousPress = MockKeyboardPress()
            let nextPress = MockKeyboardPress()
            view.controller = fixture.controller
            fixture.commandQueue.stubKeyInputSynchronized { _ in !handled }
            view.pressesBegan([previousPress], with: nil)

            // No release arrives for the previous press of the same key.
            fixture.commandQueue.stubKeyInputSynchronized { _ in handled }
            view.pressesBegan([nextPress], with: nil)
            view.pressesChanged([nextPress], with: nil)
            view.pressesEnded([nextPress], with: nil)

            XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
            ])
            XCTAssertEqual(view.nativeResponder.calls, handled ? [
                .init(phase: .began, presses: [previousPress])
            ] : [
                .init(phase: .began, presses: [nextPress]),
                .init(phase: .changed, presses: [nextPress]),
                .init(phase: .ended, presses: [nextPress])
            ])
        }
    }

    @MainActor
    func test_keyPress_freshPressAfterMissedReleaseUsesReplacementController() async throws {
        for handled in [false, true] {
            let original = try await makeController()
            let replacement = try await makeController()
            defer {
                original.controller.invalidate()
                replacement.controller.invalidate()
            }
            original.commandQueue.stubKeyInputSynchronized { _ in !handled }
            replacement.commandQueue.stubKeyInputSynchronized { _ in handled }
            let view = KeyboardTestMetalView(frame: .zero, device: nil)
            let previousPress = MockKeyboardPress()
            let nextPress = MockKeyboardPress()
            view.controller = original.controller
            view.pressesBegan([previousPress], with: nil)

            // Replacement must not turn a fresh press into a continuation of the old one.
            view.controller = replacement.controller
            view.pressesBegan([nextPress], with: nil)
            view.pressesChanged([nextPress], with: nil)
            view.pressesEnded([nextPress], with: nil)

            XCTAssertEqual(original.commandQueue.keyInputSynchronizedCalls.count, 1)
            XCTAssertEqual(replacement.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: true, isRepeat: false),
                .init(stateMachineHandle: 123, key: .A, modifiers: [], isPressed: false, isRepeat: false)
            ])
            XCTAssertEqual(view.nativeResponder.calls, handled ? [
                .init(phase: .began, presses: [previousPress])
            ] : [
                .init(phase: .began, presses: [nextPress]),
                .init(phase: .changed, presses: [nextPress]),
                .init(phase: .ended, presses: [nextPress])
            ])
        }
    }

    @MainActor
    func test_keyPress_deallocatedControllerDoesNotBlockFreshPress() async throws {
        var fixture: ControllerFixture? = try await makeController()
        weak var controller = fixture?.controller
        let view = KeyboardTestMetalView(frame: .zero, device: nil)
        let press = MockKeyboardPress()
        fixture?.commandQueue.stubKeyInputSynchronized { _ in true }
        view.controller = fixture?.controller
        view.pressesBegan([press], with: nil)

        view.controller = nil
        fixture?.controller.invalidate()
        fixture = nil
        XCTAssertNil(controller)
        view.pressesChanged([press], with: nil)
        XCTAssertTrue(view.nativeResponder.calls.isEmpty)

        let nextPress = MockKeyboardPress()
        view.pressesBegan([nextPress], with: nil)
        view.pressesEnded([nextPress], with: nil)
        XCTAssertEqual(view.nativeResponder.calls, [
            .init(phase: .began, presses: [nextPress]),
            .init(phase: .ended, presses: [nextPress])
        ])
    }

    @MainActor
    func test_keyPress_untrackedReleaseIsForwardedWithoutSendingToRive() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        let view = KeyboardTestMetalView(frame: .zero, device: nil)
        let press = MockKeyboardPress()
        view.controller = fixture.controller
        view.pressesEnded([press], with: nil)

        XCTAssertTrue(fixture.commandQueue.keyInputSynchronizedCalls.isEmpty)
        XCTAssertEqual(view.nativeResponder.calls, [.init(phase: .ended, presses: [press])])
    }

    @MainActor
    func test_keyInput_handledArrowDoesNotTraverseAndWakesRendering() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        await expectSettled(within: fixture)
        fixture.focusSystem.isFocusable = true
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }

        XCTAssertTrue(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
            .init(stateMachineHandle: fixture.stateMachine.stateMachineHandle, key: .right, modifiers: [], isPressed: true, isRepeat: false)
        ])
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
        XCTAssertFalse(fixture.controller.isSettled)
    }

    @MainActor
    func test_keyInput_unhandledArrowsTraverseAfterKeyDelivery() async throws {
        for isRepeat in [false, true] {
            // Every case starts settled so its own traversal must wake rendering.
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            fixture.focusSystem.isFocusable = true
            await expectSettled(within: fixture)
            fixture.commandQueue.stubKeyInputSynchronized { _ in false }
            fixture.commandQueue.stubFocusInDirectionSynchronized { [weak queue = fixture.commandQueue] _ in
                XCTAssertEqual(queue?.keyInputSynchronizedCalls.count, 1)
                return true
            }

            XCTAssertTrue(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: isRepeat, hasNativeFocus: true))

            XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: fixture.stateMachine.stateMachineHandle, key: .right, modifiers: [], isPressed: true, isRepeat: isRepeat)
            ])
            XCTAssertEqual(fixture.commandQueue.focusInDirectionSynchronizedCalls, [
                .init(stateMachineHandle: fixture.stateMachine.stateMachineHandle, direction: .right)
            ])
            XCTAssertFalse(fixture.controller.isSettled)
        }
    }

    @MainActor
    func test_keyInput_failedDirectionalTraversalWakesWithoutClearingFocus() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        await expectSettled(within: fixture)
        fixture.focusSystem.isFocusable = true
        fixture.commandQueue.stubKeyInputSynchronized { _ in false }
        fixture.commandQueue.stubFocusInDirectionSynchronized { _ in false }

        XCTAssertFalse(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))

        XCTAssertEqual(fixture.commandQueue.focusInDirectionSynchronizedCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
        XCTAssertFalse(fixture.controller.isSettled)
    }

    @MainActor
    func test_keyInput_withoutNativeFocusDoesNotDeliverOrWake() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        await expectSettled(within: fixture)
        fixture.focusSystem.isFocusable = true
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }

        XCTAssertFalse(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: false))
        XCTAssertTrue(fixture.commandQueue.keyInputSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.controller.isSettled)
    }

    @MainActor
    func test_keyInput_handledTabDoesNotTraverse() async throws {
        for modifiers: StateMachine.KeyModifiers in [[], [.shift]] {
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            await expectSettled(within: fixture)
            fixture.focusSystem.isFocusable = true
            fixture.commandQueue.stubKeyInputSynchronized { _ in true }

            // Authored key handling takes priority over focus traversal.
            XCTAssertTrue(fixture.controller.handleKeyInput(.tab, modifiers: modifiers, isPressed: true, isRepeat: false, hasNativeFocus: true))

            XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
                .init(stateMachineHandle: fixture.stateMachine.stateMachineHandle, key: .tab, modifiers: modifiers, isPressed: true, isRepeat: false)
            ])
            XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusNextWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.isEmpty)
            XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
            XCTAssertFalse(fixture.controller.isSettled)
        }
    }

    @MainActor
    func test_keyInput_unhandledTabTraversesAndReturnsConsumption() async throws {
        let results = [
            (moved: true, hasFocus: true, consumed: true),
            (moved: false, hasFocus: false, consumed: false),
        ]
        for modifiers: StateMachine.KeyModifiers in [[], [.shift]] {
            for result in results {
                let fixture = try await makeController()
                defer { fixture.controller.invalidate() }
                fixture.focusSystem.isFocusable = true
                fixture.commandQueue.stubKeyInputSynchronized { _ in false }
                fixture.commandQueue.stubFocusNextWithResultSynchronized { [weak queue = fixture.commandQueue] _ in
                    XCTAssertEqual(queue?.keyInputSynchronizedCalls.count, 1)
                    return .init(moved: result.moved, focusState: .init(hasFocus: result.hasFocus, expectsKeyboardInput: false))
                }
                fixture.commandQueue.stubFocusPreviousWithResultSynchronized { [weak queue = fixture.commandQueue] _ in
                    XCTAssertEqual(queue?.keyInputSynchronizedCalls.count, 1)
                    return .init(moved: result.moved, focusState: .init(hasFocus: result.hasFocus, expectsKeyboardInput: false))
                }

                XCTAssertEqual(fixture.controller.handleKeyInput(.tab, modifiers: modifiers, isPressed: true, isRepeat: false, hasNativeFocus: true), result.consumed)
                XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
                XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, modifiers.isEmpty ? 1 : 0)
                XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, modifiers.isEmpty ? 0 : 1)
                XCTAssertTrue(fixture.commandQueue.clearFocusCalls.isEmpty)
            }
        }
    }

    @MainActor
    func test_keyInput_repeatedTabTraversesOncePerDelivery() async throws {
        for modifiers: StateMachine.KeyModifiers in [[], [.shift]] {
            let fixture = try await makeController()
            defer { fixture.controller.invalidate() }
            fixture.focusSystem.isFocusable = true
            fixture.commandQueue.stubKeyInputSynchronized { _ in false }
            fixture.commandQueue.stubFocusNextWithResultSynchronized { _ in
                .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
            }
            fixture.commandQueue.stubFocusPreviousWithResultSynchronized { _ in
                .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
            }
            for (index, isRepeat) in [false, true, true].enumerated() {
                XCTAssertTrue(fixture.controller.handleKeyInput(.tab, modifiers: modifiers, isPressed: true, isRepeat: isRepeat, hasNativeFocus: true))
                XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, index + 1)
                XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.last?.isRepeat, isRepeat)
                XCTAssertEqual(fixture.commandQueue.focusNextWithResultSynchronizedCalls.count, modifiers.isEmpty ? index + 1 : 0)
                XCTAssertEqual(fixture.commandQueue.focusPreviousWithResultSynchronizedCalls.count, modifiers.isEmpty ? 0 : index + 1)
            }
        }
    }

    @MainActor
    func test_keyInput_pausedAndInvalidatedControllersIgnoreInput() async throws {
        let fixture = try await makeController()
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        fixture.controller.isPaused = true
        XCTAssertFalse(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))
        XCTAssertTrue(fixture.commandQueue.keyInputSynchronizedCalls.isEmpty)

        fixture.controller.isPaused = false
        XCTAssertTrue(fixture.controller.handleKeyInput(.enter, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))
        fixture.controller.invalidate()
        XCTAssertFalse(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))
        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_beforeFocusabilityIsKnownDeliversKeysButDoesNotTraverse() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        fixture.commandQueue.stubKeyInputSynchronized { _ in false }

        XCTAssertFalse(fixture.controller.handleKeyInput(.right, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_handledKeyCancelsPendingFocusSnapshotWithoutTraversal() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        let requested = expectation(description: "focus state requested")
        let cancelled = expectation(description: "focus state request cancelled")
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }

        _ = fixture.controller.advance(
            now: 0,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 100),
            scaleProvider: MockScaleProvider()
        )
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        fixture.stateMachineService.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }

        // A handled non-arrow cannot rely on directional fallback to cancel the snapshot.
        XCTAssertTrue(fixture.controller.handleKeyInput(.enter, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))
        await fulfillment(of: [cancelled], timeout: 1)

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_unhandledKeyWakesAndReplacesPendingFocusSnapshot() async throws {
        let fixture = try await makeController()
        defer { fixture.controller.invalidate() }
        let requested = expectation(description: "focus state requested")
        let updated = expectation(description: "post-input snapshot makes view focusable")
        fixture.commandQueue.stubRequestHasFocusNodes { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onHasFocusNodesReceived(handle, requestID: requestID, hasFocusNodes: true)
        }
        fixture.commandQueue.stubRequestFocusState { _, _ in requested.fulfill() }
        fixture.focusSystem.onIsFocusableChanged = { isFocusable in
            if isFocusable { updated.fulfill() }
        }

        _ = fixture.controller.advance(
            now: 0,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 100),
            scaleProvider: MockScaleProvider()
        )
        await fulfillment(of: [requested], timeout: 1)
        let request = try XCTUnwrap(fixture.commandQueue.requestFocusStateCalls.last)
        await expectSettled(within: fixture)
        fixture.commandQueue.stubKeyInputSynchronized { _ in false }
        let cancelled = expectation(description: "pre-input snapshot cancelled")
        fixture.stateMachineService.onRequestCancelled = { requestID in
            if requestID == request.requestID { cancelled.fulfill() }
        }

        XCTAssertFalse(fixture.controller.handleKeyInput(.X, modifiers: [], isPressed: true, isRepeat: false, hasNativeFocus: true))
        XCTAssertFalse(fixture.controller.isSettled)
        XCTAssertFalse(fixture.focusSystem.isFocusable)
        await fulfillment(of: [cancelled], timeout: 1)

        let discarded = expectation(description: "pre-input response discarded")
        fixture.stateMachineService.onFocusResponseDiscarded = { requestID in
            XCTAssertEqual(requestID, request.requestID)
            discarded.fulfill()
        }
        fixture.stateMachineService.onFocusStateReceived(
            request.stateMachineHandle,
            requestID: request.requestID,
            focusState: .init(hasFocus: false, expectsKeyboardInput: false)
        )
        await fulfillment(of: [discarded], timeout: 1)
        XCTAssertFalse(fixture.focusSystem.isFocusable)

        fixture.commandQueue.stubRequestFocusState { [weak service = fixture.stateMachineService] handle, requestID in
            service?.onFocusStateReceived(handle, requestID: requestID, focusState: .init(
                hasFocus: true, expectsKeyboardInput: false
            ))
        }
        _ = fixture.controller.advance(
            now: 1,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 100),
            scaleProvider: MockScaleProvider()
        )
        await fulfillment(of: [updated], timeout: 1)

        XCTAssertTrue(fixture.focusSystem.isFocusable)
        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.requestFocusStateCalls.count, 2)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func makeController(
        dataBind: DataBind = .none,
        fit: Fit = .contain(alignment: .center),
        delegate: MockControllerDelegate? = nil,
        hasNativeFocus: Bool = false,
        prepareStateMachine: (@MainActor (StateMachine, MockCommandQueue) async throws -> Void)? = nil
    ) async throws -> ControllerFixture {
        let delegate = delegate ?? MockControllerDelegate()
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42,
            sourceFile: file
        )

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123,
            sourceArtboard: artboard
        )

        let fileService = file.dependencies.fileService
        commandQueue.stubRequestGlobalViewModelNames { handle, requestID in
            fileService.onGlobalViewModelsListed(handle, requestID: requestID, names: ["Theme", "Shared", "First", "Second"])
        }

        try await prepareStateMachine?(stateMachine, commandQueue)

        if case .auto = dataBind {
            let fileService = file.dependencies.fileService
            commandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
                fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 456)
                return 456
            }
        }

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: dataBind,
            fit: fit
        )

        let focusSystem = MockFocusSystem()
        let controller = RiveController(
            rive: rive,
            delegate: delegate,
            focusSystem: focusSystem,
            hasNativeFocus: hasNativeFocus
        )

        return ControllerFixture(
            controller: controller,
            delegate: delegate,
            rive: rive,
            stateMachine: stateMachine,
            stateMachineService: stateMachineService,
            viewModelInstance: rive.stateMachine.mainBinding,
            commandQueue: commandQueue,
            focusSystem: focusSystem
        )
    }

    @MainActor
    private func makeViewModelInstance(
        handle: ViewModelInstance.ViewModelInstanceHandle,
        commandQueue: MockCommandQueue
    ) -> ViewModelInstance {
        let service = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        return ViewModelInstance(
            handle: handle,
            dependencies: .init(viewModelInstanceService: service)
        )
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    @MainActor
    private func makeControllerWithSemantics(
        drawableSize: CGSize = CGSize(width: 320, height: 240)
    ) async throws -> SemanticsControllerFixture {
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42,
            sourceFile: file
        )

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123,
            sourceArtboard: artboard
        )

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none
        )

        let delegate = MockControllerDelegate(drawableSize: drawableSize)
        let mockNotificationCenter = MockNotificationCenter()
        let focusSystem = MockFocusSystem()
        let controller = RiveController(
            rive: rive,
            delegate: delegate,
            focusSystem: focusSystem,
            accessibility: MockUIAccessibility.self,
            notificationCenter: mockNotificationCenter
        )
        controller.semantics = .automatic

        return SemanticsControllerFixture(
            controller: controller,
            delegate: delegate,
            rive: rive,
            stateMachine: stateMachine,
            stateMachineService: stateMachineService,
            commandQueue: commandQueue,
            mockNotificationCenter: mockNotificationCenter
        )
    }
    #endif

    @MainActor
    private func emitSettledAndAwaitPending(
        within fixture: ControllerFixture,
        requestID: UInt64
    ) async {
        let pendingExpectation = expectation(description: "hasPendingSettle is set")
        fixture.controller.onHasPendingSettleForTesting = {
            pendingExpectation.fulfill()
        }
        fixture.stateMachineService.onStateMachineSettled(
            fixture.stateMachine.stateMachineHandle, requestID: requestID
        )
        await fulfillment(of: [pendingExpectation], timeout: 1.0)
        fixture.controller.onHasPendingSettleForTesting = nil
    }

    @MainActor
    private func expectSettled(within fixture: ControllerFixture) async {
        await emitSettledAndAwaitPending(within: fixture, requestID: 1)
        fixture.controller.resolveForTesting()
        XCTAssertTrue(fixture.controller.isSettled)
    }

    @MainActor
    private func expectSettledAfterDirty(within fixture: ControllerFixture) async {
        _ = fixture.controller.advance(
            now: 0,
            isOnscreen: true,
            drawableSize: fixture.delegate.drawableSize,
            scaleProvider: fixture.delegate
        )
        await expectSettled(within: fixture)
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    @MainActor
    private func emitSettledAndAwaitPending(
        within fixture: SemanticsControllerFixture,
        requestID: UInt64
    ) async {
        let pendingExpectation = expectation(description: "hasPendingSettle is set")
        fixture.controller.onHasPendingSettleForTesting = {
            pendingExpectation.fulfill()
        }
        fixture.stateMachineService.onStateMachineSettled(
            fixture.stateMachine.stateMachineHandle, requestID: requestID
        )
        await fulfillment(of: [pendingExpectation], timeout: 1.0)
        fixture.controller.onHasPendingSettleForTesting = nil
    }

    @MainActor
    private func expectSettled(within fixture: SemanticsControllerFixture) async {
        await emitSettledAndAwaitPending(within: fixture, requestID: 1)
        fixture.controller.resolveForTesting()
        XCTAssertTrue(fixture.controller.isSettled)
    }
    #endif

    @MainActor
    private func setupStaleSettledAfterDirty() async throws -> ControllerFixture {
        let fixture = try await makeController(dataBind: .auto)
        await expectSettled(within: fixture)

        _ = fixture.controller.advance(
            now: 10,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        fixture.viewModelInstance?.setValue(of: StringProperty(path: "test"), to: "value")

        await emitSettledAndAwaitPending(within: fixture, requestID: 2)

        _ = fixture.controller.advance(
            now: 10.5,
            isOnscreen: true,
            drawableSize: CGSize(width: 100, height: 200),
            scaleProvider: MockScaleProvider()
        )

        return fixture
    }

    @MainActor
    private func expectIsSettled(
        _ expectedValue: Bool,
        within fixture: ControllerFixture,
        trigger: (@MainActor () async -> Void)? = nil
    ) async {
        guard let trigger else {
            XCTAssertEqual(fixture.controller.isSettled, expectedValue)
            return
        }

        let settledExpectation = expectation(description: "controller isSettled emits \(expectedValue)")
        fixture.controller.onIsSettledChangedForTesting = { value in
            guard value == expectedValue else { return }
            settledExpectation.fulfill()
        }

        await trigger()

        await fulfillment(of: [settledExpectation], timeout: 1.0)

        fixture.controller.onIsSettledChangedForTesting = nil
    }
}

/// Exercises event routing without a window, focus engine, or physical keyboard.
@MainActor
private final class KeyboardTestMetalView: UIKitMetalView {
    let nativeResponder = MockKeyboardResponder()
    override var isFocused: Bool { true }
    override var next: UIResponder? { nativeResponder }
}

@MainActor
private final class MockKeyboardResponder: UIResponder {
    struct Call: Equatable {
        let phase: UIPress.Phase
        let presses: Set<UIPress>
    }
    private(set) var calls: [Call] = []

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        calls.append(.init(phase: .began, presses: presses))
    }
    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        calls.append(.init(phase: .changed, presses: presses))
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        calls.append(.init(phase: .ended, presses: presses))
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        calls.append(.init(phase: .cancelled, presses: presses))
    }
}

private final class MockKeyboardPress: UIPress {
    override var key: UIKey? { MockKeyboardKey() }
}

private final class MockKeyboardKey: UIKey {
    override var keyCode: UIKeyboardHIDUsage { .keyboardA }
    override var modifierFlags: UIKeyModifierFlags { [] }
}

private struct ControllerFixture {
    let controller: RiveController
    let delegate: MockControllerDelegate
    let rive: Rive
    let stateMachine: StateMachine
    let stateMachineService: StateMachineService
    let viewModelInstance: ViewModelInstance?
    let commandQueue: MockCommandQueue
    let focusSystem: MockFocusSystem
}

private struct MockScaleProvider: ScaleProvider {
    var nativeScale: CGFloat?
    var displayScale: CGFloat

    init(nativeScale: CGFloat? = nil, displayScale: CGFloat = 1) {
        self.nativeScale = nativeScale
        self.displayScale = displayScale
    }
}

private class MockControllerDelegate: RiveControllerDelegate {
    var drawableSize: CGSize
    var nativeScale: CGFloat?
    var displayScale: CGFloat
    #if !os(macOS) || RIVE_MAC_CATALYST
    var accessibilityContainer: AnyObject = NSObject()
    private var isModal = false

    func controller(_ controller: RiveController, didUpdateModalState isModal: Bool) -> Bool {
        let transitioned = self.isModal != isModal
        self.isModal = isModal
        return transitioned
    }
    #endif

    init(
        drawableSize: CGSize = CGSize(width: 320, height: 240),
        nativeScale: CGFloat? = nil,
        displayScale: CGFloat = 1
    ) {
        self.drawableSize = drawableSize
        self.nativeScale = nativeScale
        self.displayScale = displayScale
    }
}

// MARK: - Semantics Fixture

#if !os(macOS) || RIVE_MAC_CATALYST

private struct SemanticsControllerFixture {
    let controller: RiveController
    let delegate: MockControllerDelegate
    let rive: Rive
    let stateMachine: StateMachine
    let stateMachineService: StateMachineService
    let commandQueue: MockCommandQueue
    let mockNotificationCenter: MockNotificationCenter
}

#endif
