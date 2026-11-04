import XCTest
@preconcurrency @testable import RiveRuntime
#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

final class UIKitFocusSystemTests: XCTestCase {
    @MainActor
    func test_entry_reportsSequentialAndWrapDirectionsOnlyAfterCommit() {
        let cases: [(UIFocusHeading, FocusTraversalDirection)] = [
            (.next, .next), (.first, .next), (.previous, .previous), (.last, .previous)
        ]
        for (heading, direction) in cases {
            for useDescendant in [false, true] {
                let fixture = makeFixture()
                fixture.focusSystem.isFocusable = true
                let target = useDescendant ? fixture.riveChildView : fixture.riveView
                XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: fixture.previousView, to: target, heading: heading))
                XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
                fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: target, heading: heading)
                XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [direction])
            }
        }
    }

    @MainActor
    func test_entry_withoutSequentialHeadingReportsNoDirection() {
        for heading: UIFocusHeading in [[], .up, .down, .left, .right] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: heading)
            XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
            XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        }
    }

    @MainActor
    func test_initialEntryWithoutHeadingIsAllowedAndReportedOnlyAfterCommit() {
        for useDescendant in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            let target = useDescendant ? fixture.riveChildView : fixture.riveView

            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: nil, to: target, heading: []
            ))
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)

            fixture.focusSystem.didUpdateFocus(from: nil, to: target, heading: [])
            XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
            XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        }
    }

    @MainActor
    func test_becomingFocusableDoesNotStealFocusFromNativeItem() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)

        XCTAssertFalse(fixture.focusSystem.shouldUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: []
        ))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_restorationWithoutFocusedItemIsAllowedAfterExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: nil, heading: [])
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)

        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: nil, to: fixture.riveView, heading: []))
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)

        fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: [])
        XCTAssertEqual(fixture.delegate.entryCalls.count, 2)
        XCTAssertNil(fixture.delegate.entryCalls.last?.direction)
    }

    @MainActor
    func test_outgoingProposalsNeverRepeatKeyboardTraversalOrClearFocus() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        for heading: UIFocusHeading in [.next, .first, .previous, .last, .up, .down, .left, .right, []] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: fixture.riveView, to: fixture.nextView, heading: heading))
        }
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_committedExitReportsExitEvenAfterFocusabilityIsDisabled() {
        for disabled in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = !disabled
            fixture.focusSystem.didUpdateFocus(from: fixture.riveChildView, to: nil, heading: [])
            XCTAssertEqual(fixture.delegate.exitCallCount, 1)
        }
    }

    @MainActor
    func test_internalAndUnrelatedUpdatesDoNotReportEntryOrExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        for heading: UIFocusHeading in [[], .next, .previous] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.riveView, to: fixture.riveChildView, heading: heading
            ))
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.previousView, to: fixture.nextView, heading: heading
            ))
        }
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: fixture.riveChildView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.nextView, heading: .next)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_disabledEntryDoesNotNotifyController() {
        let fixture = makeFixture()
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_invalidateDetachesDelegateAndIgnoresUpdates() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.invalidate()
        XCTAssertNil(fixture.focusSystem.delegate)
        fixture.focusSystem.delegate = fixture.delegate
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: fixture.nextView, heading: .next)
        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: nil, to: fixture.riveView, heading: []))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_nativeEntryTraversesOnceAndOnlyCommittedExitClearsFocus() {
        let fixture = makeFixture()
        let commandQueue = MockCommandQueue()
        let service = StateMachineService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: service), stateMachineHandle: 123
        )
        commandQueue.stubDeleteStateMachine { [weak commandQueue, weak service] handle in
            guard let requestID = commandQueue?.deleteStateMachineCalls.last?.requestID else { return }
            service?.onStateMachineDeleted(handle, requestID: requestID)
        }
        let controller = FocusController(dependencies: .init(
            stateMachine: stateMachine, focusSystem: fixture.focusSystem
        ))
        defer { controller.invalidate() }

        // Polling eligibility is covered separately by FocusControllerTests.
        fixture.focusSystem.isFocusable = true

        commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }

        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: .next
        ))
        fixture.focusSystem.didUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: .next
        )
        XCTAssertEqual(commandQueue.focusNextWithResultSynchronizedCalls.map(\.stateMachineHandle), [123])

        // UIKit may propose both sequential and wrap destinations. Neither
        // proposal may repeat traversal or clear focus before a committed exit.
        for heading: UIFocusHeading in [.next, .first] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.riveView, to: fixture.nextView, heading: heading
            ))
        }
        XCTAssertEqual(commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertTrue(commandQueue.clearFocusCalls.isEmpty)

        fixture.focusSystem.didUpdateFocus(
            from: fixture.riveView, to: fixture.nextView, heading: .next
        )
        XCTAssertEqual(commandQueue.clearFocusCalls.count, 1)
        XCTAssertEqual(commandQueue.clearFocusCalls.first?.stateMachineHandle, 123)
    }

    @MainActor
    private func makeFixture() -> UIKitFocusSystemFixture { UIKitFocusSystemFixture() }
}

@MainActor
private final class UIKitFocusSystemFixture {
    let focusEnvironment = UIView()
    let riveView = UIView()
    let riveChildView = UIView()
    let previousView = UIView()
    let nextView = UIView()
    let delegate = MockFocusSystemDelegate()
    let focusSystem: UIKitFocusSystem

    init() {
        focusEnvironment.addSubview(riveView)
        riveView.addSubview(riveChildView)
        focusSystem = UIKitFocusSystem(
            dependencies: .init(focusEnvironment: focusEnvironment)
        )
        focusSystem.delegate = delegate
    }
}

@MainActor
private final class MockFocusSystemDelegate: FocusSystemDelegate {
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
