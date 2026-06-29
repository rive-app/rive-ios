//
//  RiveControllerTests.swift
//  RiveRuntimeTests
//
//  Created by Cursor Assistant on 2/20/26.
//

import XCTest
@preconcurrency @testable import RiveRuntime

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
    func test_advance_whenLayoutFitAndDrawableSizeChanges_reappliesArtboardSize() async throws {
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
        XCTAssertEqual(call.scale, 1)
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

    // MARK: - Helpers

    @MainActor
    private func makeController(
        dataBind: DataBind = .none,
        fit: Fit = .contain(alignment: .center),
        delegate: MockControllerDelegate? = nil
    ) async throws -> ControllerFixture {
        let delegate = delegate ?? MockControllerDelegate()
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42
        )

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123
        )

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

        let controller = RiveController(rive: rive, delegate: delegate)

        return ControllerFixture(
            controller: controller,
            delegate: delegate,
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

    #if !os(macOS) || RIVE_MAC_CATALYST
    @MainActor
    private func makeControllerWithSemantics(
        drawableSize: CGSize = CGSize(width: 320, height: 240)
    ) async throws -> SemanticsControllerFixture {
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42
        )

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123
        )

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none
        )

        let delegate = MockControllerDelegate(drawableSize: drawableSize)
        let mockNotificationCenter = MockNotificationCenter()
        let controller = RiveController(
            rive: rive,
            delegate: delegate,
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
    let delegate: MockControllerDelegate
    let rive: Rive
    let stateMachine: StateMachine
    let stateMachineService: StateMachineService
    let dirtyFlow: (@MainActor () -> AsyncStream<Void>)?
    let viewModelInstance: ViewModelInstance?
    let commandQueue: MockCommandQueue
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
