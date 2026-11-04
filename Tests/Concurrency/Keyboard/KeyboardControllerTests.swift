//
//  KeyboardControllerTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

final class KeyboardControllerTests: XCTestCase {
    @MainActor
    func test_keyInput_forwardsPressRepeatAndRelease() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }

        _ = fixture.controller.keyInput(.enter, modifiers: [.shift, .control], isPressed: true, isRepeat: false)
        _ = fixture.controller.keyInput(.space, modifiers: [.alt, .meta], isPressed: true, isRepeat: true)
        _ = fixture.controller.keyInput(.right, modifiers: [], isPressed: false, isRepeat: false)

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls, [
            .init(stateMachineHandle: 123, key: .enter, modifiers: [.shift, .control], isPressed: true, isRepeat: false),
            .init(stateMachineHandle: 123, key: .space, modifiers: [.alt, .meta], isPressed: true, isRepeat: true),
            .init(stateMachineHandle: 123, key: .right, modifiers: [], isPressed: false, isRepeat: false),
        ])
        XCTAssertEqual(fixture.delegate.wakeCalls.count, 3)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_handledInputReturnsTrueAndRequestsWakeAfterDelivery() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { [weak delegate = fixture.delegate] _ in
            XCTAssertEqual(delegate?.wakeCalls.count, 0)
            return true
        }

        XCTAssertTrue(fixture.controller.keyInput(.enter, modifiers: [], isPressed: true, isRepeat: false))

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCalls.count, 1)
        XCTAssertTrue(fixture.delegate.wakeCalls.first?.controller === fixture.controller)
    }

    @MainActor
    func test_keyInput_unhandledArrowReturnsFalseAndWakesAfterDeliveryWithoutTraversal() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { [weak delegate = fixture.delegate] _ in
            XCTAssertTrue(delegate?.wakeCalls.isEmpty == true)
            return false
        }

        XCTAssertFalse(fixture.controller.keyInput(.right, modifiers: [], isPressed: true, isRepeat: false))

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCalls.count, 1)
        XCTAssertTrue(fixture.commandQueue.focusInDirectionSynchronizedCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_whilePausedDoesNotForwardOrWake() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        fixture.controller.isPaused = true

        XCTAssertFalse(fixture.controller.keyInput(.enter, modifiers: [], isPressed: true, isRepeat: false))

        XCTAssertTrue(fixture.commandQueue.keyInputSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.delegate.wakeCalls.isEmpty)
    }

    @MainActor
    func test_keyInput_afterResumingForwardsAndWakes() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        fixture.controller.isPaused = true
        fixture.controller.isPaused = false

        XCTAssertTrue(fixture.controller.keyInput(.enter, modifiers: [], isPressed: true, isRepeat: false))

        XCTAssertEqual(fixture.commandQueue.keyInputSynchronizedCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeCalls.count, 1)
    }

    @MainActor
    func test_invalidate_permanentlyPreventsInputEvenAfterResuming() {
        let fixture = KeyboardControllerFixture()
        fixture.commandQueue.stubKeyInputSynchronized { _ in true }
        fixture.controller.invalidate()
        fixture.controller.invalidate()
        fixture.controller.isPaused = true
        fixture.controller.isPaused = false

        XCTAssertFalse(fixture.controller.keyInput(.enter, modifiers: [], isPressed: true, isRepeat: false))

        XCTAssertTrue(fixture.commandQueue.keyInputSynchronizedCalls.isEmpty)
        XCTAssertTrue(fixture.delegate.wakeCalls.isEmpty)
    }
}

@MainActor
private final class KeyboardControllerFixture {
    let commandQueue = MockCommandQueue()
    let delegate = MockKeyboardControllerDelegate()
    let controller: KeyboardController

    init() {
        let service = StateMachineService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: service), stateMachineHandle: 123
        )
        controller = KeyboardController(dependencies: .init(stateMachine: stateMachine))
        controller.delegate = delegate
    }
}

@MainActor
private final class MockKeyboardControllerDelegate: KeyboardControllerDelegate {
    struct WakeCall {
        let controller: KeyboardController
    }

    private(set) var wakeCalls: [WakeCall] = []

    func keyboardControllerDidRequestWake(_ controller: KeyboardController) {
        wakeCalls.append(.init(controller: controller))
    }
}
