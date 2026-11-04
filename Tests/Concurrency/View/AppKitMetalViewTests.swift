//
//  AppKitMetalViewTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/14/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if os(macOS) && !RIVE_MAC_CATALYST
import AppKit
import XCTest
@preconcurrency @testable import RiveRuntime

final class AppKitMetalViewTests: XCTestCase {
    @MainActor
    func test_acceptsFirstResponder_matchesFocusSystemAvailability() {
        let fixture = makeFixture()

        XCTAssertFalse(fixture.riveView.acceptsFirstResponder)

        fixture.focusSystem.isFocusable = true

        XCTAssertTrue(fixture.riveView.acceptsFirstResponder)
    }

    @MainActor
    func test_nextKeyViewTraversal_reportsNativeEntryAndExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        XCTAssertTrue(fixture.window.makeFirstResponder(fixture.beforeView))

        fixture.window.selectNextKeyView(nil)

        XCTAssertTrue(fixture.window.firstResponder === fixture.riveView)
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])

        fixture.window.selectNextKeyView(nil)

        XCTAssertTrue(fixture.window.firstResponder === fixture.afterView)
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)
    }

    @MainActor
    func test_previousKeyViewTraversal_reportsNativeEntryAndExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        XCTAssertTrue(fixture.window.makeFirstResponder(fixture.afterView))

        fixture.window.selectPreviousKeyView(nil)

        XCTAssertTrue(fixture.window.firstResponder === fixture.riveView)
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.previous])

        fixture.window.selectPreviousKeyView(nil)

        XCTAssertTrue(fixture.window.firstResponder === fixture.beforeView)
        XCTAssertEqual(
            fixture.delegate.entryCalls.map(\.direction),
            [.previous]
        )
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)
    }

    @MainActor
    func test_directFirstResponderChanges_reportEntryWithoutDirectionAndExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true

        XCTAssertTrue(fixture.window.makeFirstResponder(fixture.riveView))
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
        XCTAssertNil(fixture.delegate.entryCalls.first?.direction)

        XCTAssertTrue(fixture.window.makeFirstResponder(fixture.afterView))
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
        XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)
    }

    @MainActor
    private func makeFixture() -> AppKitMetalViewFixture {
        AppKitMetalViewFixture()
    }
}

@MainActor
private final class AppKitMetalViewFixture {
    let window: NSWindow
    let beforeView = TestFocusableView()
    let riveView = AppKitMetalView(frame: .zero, device: nil)
    let afterView = TestFocusableView()
    let focusSystem: AppKitFocusSystem
    let delegate = MockAppKitMetalViewDelegate()

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        focusSystem = AppKitFocusSystem()

        window.contentView?.addSubview(beforeView)
        window.contentView?.addSubview(riveView)
        window.contentView?.addSubview(afterView)
        beforeView.nextKeyView = riveView
        riveView.nextKeyView = afterView
        afterView.nextKeyView = beforeView

        focusSystem.delegate = delegate
        riveView.focusSystem = focusSystem
    }
}

@MainActor
private final class TestFocusableView: NSView {
    override var acceptsFirstResponder: Bool { true }
}

@MainActor
private final class MockAppKitMetalViewDelegate: FocusSystemDelegate {
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
