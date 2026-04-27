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
            scaleProvider: MockScaleProvider(nativeScale: 3, displayScale: 1)
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
    func test_fitChangedToLayout_withNilDrawableSizeProvider_fallsBackToZeroSize() async throws {
        // A `[weak self]` drawable-size provider that returns nil (e.g. the
        // owning view has deallocated) must not crash; the controller
        // resolves the fallback to `.zero`.
        let fixture = try await makeController(
            dataBind: .none,
            drawableSize: nil,
            scaleProvider: MockScaleProvider()
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
    func test_fitChangedToLayout_withNilScaleProvider_fallsBackToUnitScale() async throws {
        // A `[weak self]` scale provider that returns nil must not crash; the
        // controller resolves the fallback to scale factor 1.
        let fixture = try await makeController(
            dataBind: .none,
            scaleProvider: nil
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

    @MainActor
    func test_init_appliesLayoutFitSetBeforeControllerCreated() async throws {
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

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none
        )

        // Set layout fit BEFORE controller exists (simulates the bug scenario)
        rive.fit = .layout(scaleFactor: .automatic)

        let controller = RiveController(
            rive: rive,
            drawableSizeProvider: { CGSize(width: 320, height: 240) },
            scaleProvider: { MockScaleProvider() }
        )
        _ = controller // silence unused warning

        // The controller should have applied the current layout fit on init,
        // calling setArtboardSize even though the fitDidChange event was missed.
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.count, 1)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.first?.width, 320)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.first?.height, 240)
    }

    @MainActor
    func test_init_appliesLayoutFitFromRiveInit() async throws {
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

        // Pass layout fit directly in Rive init
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none,
            fit: .layout(scaleFactor: .automatic)
        )

        let controller = RiveController(
            rive: rive,
            drawableSizeProvider: { CGSize(width: 400, height: 300) },
            scaleProvider: { MockScaleProvider() }
        )
        _ = controller

        // The controller should apply the layout fit on init even though
        // no fitDidChange event was ever published (fit was set in Rive.init).
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.count, 1)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.first?.width, 400)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.first?.height, 300)
    }

    @MainActor
    func test_applyCurrentFit_updatesArtboardSizeWhenBoundsChange() async throws {
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

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none,
            fit: .layout(scaleFactor: .automatic)
        )

        var currentDrawableSize = CGSize.zero
        let controller = RiveController(
            rive: rive,
            drawableSizeProvider: { currentDrawableSize },
            scaleProvider: { MockScaleProvider() }
        )

        // Initial call had zero drawable size
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.count, 1)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.first?.width, 0)

        // Simulate drawable size becoming available (e.g. drawableSizeWillChange)
        currentDrawableSize = CGSize(width: 402, height: 400)
        controller.applyCurrentFit()

        XCTAssertEqual(commandQueue.setArtboardSizeCalls.count, 2)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.last?.width, 402)
        XCTAssertEqual(commandQueue.setArtboardSizeCalls.last?.height, 400)
    }

    // MARK: - Helpers

    @MainActor
    private func makeController(
        dataBind: DataBind = .none,
        fit: Fit = .contain(alignment: .center),
        drawableSize: CGSize? = CGSize(width: 320, height: 240),
        scaleProvider: ScaleProvider? = nil
    ) async throws -> ControllerFixture {
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

        let controller = RiveController(
            rive: rive,
            drawableSizeProvider: { drawableSize },
            scaleProvider: { scaleProvider }
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
    var nativeScale: CGFloat?
    var displayScale: CGFloat

    init(nativeScale: CGFloat? = nil, displayScale: CGFloat = 1) {
        self.nativeScale = nativeScale
        self.displayScale = displayScale
    }
}
