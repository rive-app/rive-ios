//
//  AppKitFocusSystemTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/14/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if os(macOS) && !RIVE_MAC_CATALYST
import AppKit
import XCTest
@preconcurrency @testable import RiveRuntime

final class AppKitFocusSystemTests: XCTestCase {
    @MainActor
    func test_isFocusable_doesNotRecalculateHostKeyViewLoop() {
        let fixture = makeFixture()
        let initialCallCount = fixture.window.recalculateKeyViewLoopCallCount

        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.isFocusable = false

        XCTAssertEqual(
            fixture.window.recalculateKeyViewLoopCallCount,
            initialCallCount
        )
    }

    @MainActor
    func test_didBecomeFirstResponder_reportsForwardEntry() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true

        fixture.focusSystem.didBecomeFirstResponder(
            in: fixture.focusEnvironment,
            selectionDirection: .selectingNext
        )

        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])
    }

    @MainActor
    func test_didBecomeFirstResponder_reportsBackwardEntry() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true

        fixture.focusSystem.didBecomeFirstResponder(
            in: fixture.focusEnvironment,
            selectionDirection: .selectingPrevious
        )

        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.previous])
    }

    @MainActor
    func test_didBecomeFirstResponder_reportsDirectEntryWithoutDirection() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true

        fixture.focusSystem.didBecomeFirstResponder(
            in: fixture.focusEnvironment,
            selectionDirection: .directSelection
        )

        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
        XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
    }

    @MainActor
    func test_didBecomeFirstResponder_ignoresEntryWhenNotFocusable() {
        let fixture = makeFixture()

        fixture.focusSystem.didBecomeFirstResponder(
            in: fixture.focusEnvironment,
            selectionDirection: .selectingNext
        )

        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_didResignFirstResponder_notifiesDelegate() {
        let fixture = makeFixture()

        fixture.focusSystem.didResignFirstResponder()

        XCTAssertEqual(fixture.delegate.exitCallCount, 1)
    }

    @MainActor
    func test_invalidate_ignoresResponderChanges() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true

        fixture.focusSystem.invalidate()
        fixture.focusSystem.didBecomeFirstResponder(
            in: fixture.focusEnvironment,
            selectionDirection: .selectingNext
        )
        fixture.focusSystem.didResignFirstResponder()

        XCTAssertNil(fixture.focusSystem.delegate)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    private func makeFixture() -> AppKitFocusSystemFixture {
        AppKitFocusSystemFixture()
    }
}

@MainActor
private final class AppKitFocusSystemFixture {
    let window: TestAppKitFocusWindow
    let focusEnvironment = NSView()
    let delegate = MockAppKitFocusSystemDelegate()
    let focusSystem: AppKitFocusSystem

    init() {
        window = TestAppKitFocusWindow()
        focusSystem = AppKitFocusSystem()
        window.contentView?.addSubview(focusEnvironment)
        focusSystem.delegate = delegate
    }
}

@MainActor
private final class TestAppKitFocusWindow: NSWindow {
    private(set) var recalculateKeyViewLoopCallCount = 0

    override func recalculateKeyViewLoop() {
        recalculateKeyViewLoopCallCount += 1
    }
}

@MainActor
private final class MockAppKitFocusSystemDelegate: FocusSystemDelegate {
    struct EntryCall {
        let direction: FocusTraversalDirection?
    }
    private(set) var entryCalls: [EntryCall] = []
    private(set) var exitCallCount = 0

    func focusSystem(_ focusSystem: any FocusSystem, didEnter direction: FocusTraversalDirection?) -> Bool {
        entryCalls.append(.init(direction: direction))
        return true
    }

    func focusSystemDidExit(_ focusSystem: any FocusSystem) {
        exitCallCount += 1
    }
}
#endif
