//
//  RiveControllerTests.swift
//  RiveRuntimeTests
//
//  Created by Cursor Assistant on 2/20/26.
//

import XCTest
@_spi(RiveExperimental) @preconcurrency @testable import RiveRuntime

final class RiveControllerTests: XCTestCase {
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

    // MARK: - Helpers

    @MainActor
    private func makeController(
        dataBind: DataBind = .none
    ) async throws -> ControllerFixture {
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42
        )

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123
        )

        if case .auto = dataBind {
            commandQueue.stubCreateDefaultViewModelInstance { _, _, _, _ in
                return 456
            }
        }

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: dataBind
        )

        let controller = RiveController(
            rive: rive,
            boundsProvider: { CGSize(width: 320, height: 240) }
        )

        return ControllerFixture(
            controller: controller,
            rive: rive,
            stateMachine: stateMachine,
            stateMachineService: stateMachineService,
            dirtyFlow: rive.viewModelInstance.map { viewModelInstance in
                return { @MainActor in viewModelInstance.dirtyStream() }
            },
            viewModelInstance: rive.viewModelInstance,
            commandQueue: commandQueue
        )
    }

    @MainActor
    private func expectSettled(within fixture: ControllerFixture) async {
        await expectIsSettled(true, within: fixture) {
            fixture.stateMachineService.onStateMachineSettled(fixture.stateMachine.stateMachineHandle, requestID: 1)
        }
    }

    @MainActor
    private func expectDirty(within fixture: ControllerFixture, trigger: @MainActor () -> Void) async {
        guard let dirtyFlow = fixture.dirtyFlow else {
            XCTFail("Expected dirty flow to be available for this fixture")
            return
        }

        let dirtyExpectation = expectation(description: "view model dirty flow emits")
        let waitForDirtyTask = Task { @MainActor in
            var iterator = dirtyFlow().makeAsyncIterator()
            _ = await iterator.next()
            dirtyExpectation.fulfill()
        }

        trigger()

        await fulfillment(of: [dirtyExpectation], timeout: 1.0)
        waitForDirtyTask.cancel()
    }

    @MainActor
    private func expectIsSettled(
        _ expectedValue: Bool,
        within fixture: ControllerFixture,
        trigger: (@MainActor () -> Void)? = nil
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

        trigger()

        await fulfillment(of: [settledExpectation], timeout: 1.0)

        fixture.controller.onIsSettledChangedForTesting = nil
    }
}

private struct ControllerFixture {
    let controller: RiveController
    let rive: Rive
    let stateMachine: StateMachine
    let stateMachineService: StateMachineService
    let dirtyFlow: (@MainActor () -> AsyncStream<Void>)?
    let viewModelInstance: ViewModelInstance?
    let commandQueue: MockCommandQueue
}

private struct MockScaleProvider: ScaleProvider {
    var nativeScale: CGFloat? { nil }
    var displayScale: CGFloat { 1 }
}
