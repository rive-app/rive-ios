//
//  SemanticsControllerTests.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/5/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import XCTest
import UIKit
@testable import RiveRuntime

@MainActor
class SemanticsControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockUIAccessibility.reset()
    }

    // MARK: - Default State

    func test_default_off_noManager() {
        let fixture = makeFixture()

        XCTAssertNil(fixture.controller.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 0)
    }

    func test_default_off_accessibilityElementsIsEmpty() {
        let fixture = makeFixture()

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 0)
    }

    // MARK: - Semantics .on

    func test_on_createsManager() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        XCTAssertNotNil(fixture.controller.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 1)
    }

    func test_on_requestsWake() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        XCTAssertEqual(fixture.delegate.wakeRequestCount, 1)
    }

    func test_on_ignoresVoiceOverState() {
        MockUIAccessibility.isVoiceOverRunning = false
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        XCTAssertNotNil(fixture.controller.manager)
    }

    // MARK: - Semantics .automatic

    func test_automatic_voiceOverOn_createsManager() {
        MockUIAccessibility.isVoiceOverRunning = true
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic

        XCTAssertNotNil(fixture.controller.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 1)
    }

    func test_automatic_voiceOverOff_doesNotCreateManager() {
        MockUIAccessibility.isVoiceOverRunning = false
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic

        XCTAssertNil(fixture.controller.manager)
        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, 0)
    }

    func test_automatic_voiceOverNotification_turnsOn_createsManager() async {
        MockUIAccessibility.isVoiceOverRunning = false
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic
        XCTAssertNil(fixture.controller.manager)

        MockUIAccessibility.isVoiceOverRunning = true
        fixture.notificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNotNil(fixture.controller.manager)
    }

    func test_automatic_voiceOverNotification_turnsOff_removesManager() async {
        MockUIAccessibility.isVoiceOverRunning = true
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic
        XCTAssertNotNil(fixture.controller.manager)

        MockUIAccessibility.isVoiceOverRunning = false
        fixture.notificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNil(fixture.controller.manager)
    }

    // MARK: - Mode Transitions

    func test_on_to_off_removesManager() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        XCTAssertNotNil(fixture.controller.manager)

        fixture.controller.semantics = .off

        XCTAssertNil(fixture.controller.manager)
        XCTAssertEqual(fixture.controller.accessibilityElements.count, 0)
    }

    func test_off_to_on_createsManager() {
        let fixture = makeFixture()
        XCTAssertNil(fixture.controller.manager)

        fixture.controller.semantics = .on

        XCTAssertNotNil(fixture.controller.manager)
    }

    func test_automatic_to_off_removesObserverAndManager() async {
        MockUIAccessibility.isVoiceOverRunning = true
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic
        XCTAssertNotNil(fixture.controller.manager)

        fixture.controller.semantics = .off

        XCTAssertNil(fixture.controller.manager)

        MockUIAccessibility.isVoiceOverRunning = false
        fixture.notificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNil(fixture.controller.manager)
    }

    func test_automatic_to_on_removesObserverAndKeepsManager() async {
        MockUIAccessibility.isVoiceOverRunning = true
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic
        XCTAssertNotNil(fixture.controller.manager)

        fixture.controller.semantics = .on
        XCTAssertNotNil(fixture.controller.manager)

        MockUIAccessibility.isVoiceOverRunning = false
        fixture.notificationCenter.fire(name: UIAccessibility.voiceOverStatusDidChangeNotification)
        await Task.yield()

        XCTAssertNotNil(fixture.controller.manager)
    }

    func test_on_to_automatic_voiceOverOff_stopsSemantics() {
        MockUIAccessibility.isVoiceOverRunning = false
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        XCTAssertNotNil(fixture.controller.manager)

        fixture.controller.semantics = .automatic

        XCTAssertNil(fixture.controller.manager)
    }

    func test_on_to_automatic_voiceOverOn_keepsManager() {
        MockUIAccessibility.isVoiceOverRunning = true
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        XCTAssertNotNil(fixture.controller.manager)

        fixture.controller.semantics = .automatic

        XCTAssertNotNil(fixture.controller.manager)
    }

    func test_settingSameValue_isNoOp() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let enableCallCount = fixture.commandQueue.enableSemanticsCalls.count

        fixture.controller.semantics = .on

        XCTAssertEqual(fixture.commandQueue.enableSemanticsCalls.count, enableCallCount)
    }

    // MARK: - Diff Forwarding

    func test_commitDiffs_forwardsToManager() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let diff = makeDiff(
            added: [makeTextDiffNode(id: 1, label: "Hello")]
        )
        fixture.controller.manager?.enqueue(diff: diff)
        fixture.controller.commitDiffs()

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 1)
        XCTAssertEqual(fixture.controller.accessibilityElements.first?.accessibilityLabel, "Hello")
    }

    func test_drainDiffs_whenActive_callsStateMachine() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        fixture.controller.drainDiffs(
            fit: .contain,
            alignment: .center,
            scaleFactor: 1.0,
            viewBounds: CGSize(width: 640, height: 480)
        )

        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.first?.viewBounds, CGSize(width: 640, height: 480))
    }

    func test_drainDiffs_whenInactive_doesNotCallStateMachine() {
        let fixture = makeFixture()

        fixture.controller.drainDiffs(
            fit: .contain,
            alignment: .center,
            scaleFactor: 1.0,
            viewBounds: CGSize(width: 640, height: 480)
        )

        XCTAssertEqual(fixture.commandQueue.drainSemanticsDiffCalls.count, 0)
    }

    // MARK: - Delegate Callbacks (SemanticsManagerDelegate)

    func test_didFireAction_callsStateMachineAndRequestsWake() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!
        fixture.delegate.wakeRequestCount = 0

        fixture.controller.manager(manager, didFireAction: .tap, forNodeID: 42)

        XCTAssertEqual(fixture.commandQueue.fireSemanticActionCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.fireSemanticActionCalls.first?.semanticNodeID, 42)
        XCTAssertEqual(fixture.delegate.wakeRequestCount, 1)
    }

    func test_didRequestFocus_callsStateMachineAndRequestsWake() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!
        fixture.delegate.wakeRequestCount = 0

        fixture.controller.manager(manager, didRequestFocusForNodeID: 7)

        XCTAssertEqual(fixture.commandQueue.requestSemanticFocusCalls.count, 1)
        XCTAssertEqual(fixture.commandQueue.requestSemanticFocusCalls.first?.semanticNodeID, 7)
        XCTAssertEqual(fixture.delegate.wakeRequestCount, 1)
    }

    func test_didRequestClearFocus_callsStateMachineAndRequestsWake() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!
        fixture.delegate.wakeRequestCount = 0

        fixture.controller.managerDidRequestClearFocus(manager)

        XCTAssertEqual(fixture.commandQueue.clearSemanticFocusCalls.count, 1)
        XCTAssertEqual(fixture.delegate.wakeRequestCount, 1)
    }

    func test_didCommitDiffs_postsLayoutChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    func test_didCommitDiffs_modalEnter_postsScreenChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: true)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .screenChanged)
    }

    func test_didCommitDiffs_modalExit_postsScreenChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!

        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: true)

        MockUIAccessibility.postedNotifications = []
        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .screenChanged)
    }

    func test_didCommitDiffs_noModalTransition_postsLayoutChanged() {
        let fixture = makeFixture()
        fixture.delegate.container = UIView()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!

        MockUIAccessibility.postedNotifications = []
        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: false)

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    func test_stopSemantics_whileModal_clearsModalAndPostsScreenChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on
        let manager = fixture.controller.manager!

        fixture.controller.manager(manager, didCommitDiffsWithFocusedElement: nil, isModal: true)

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semantics = .off

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .screenChanged)
    }

    func test_stopSemantics_whileNotModal_doesNotPostScreenChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        MockUIAccessibility.postedNotifications = []
        fixture.controller.semantics = .off

        XCTAssertTrue(MockUIAccessibility.postedNotifications.isEmpty)
    }

    func test_stopSemantics_clearsSemanticFocus() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let clearCountBefore = fixture.commandQueue.clearSemanticFocusCalls.count
        fixture.controller.semantics = .off

        XCTAssertEqual(fixture.commandQueue.clearSemanticFocusCalls.count, clearCountBefore + 1)
    }

    // MARK: - Notification Suppression (End-to-End)

    func test_commitDiffs_addedNodes_postsLayoutChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let diff = makeDiff(added: [makeTextDiffNode(id: 1, label: "Hello")])
        fixture.controller.manager?.enqueue(diff: diff)

        MockUIAccessibility.postedNotifications = []
        fixture.controller.commitDiffs()

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    func test_commitDiffs_geometryOnly_doesNotPostNotification() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let addDiff = makeDiff(added: [makeTextDiffNode(id: 1, label: "Hello")])
        fixture.controller.manager?.enqueue(diff: addDiff)
        fixture.controller.commitDiffs()

        MockUIAccessibility.postedNotifications = []
        let geoDiff = makeGeometryDiff(
            rootID: 1,
            updates: [SemanticsBoundsUpdate(id: 1, minX: 10, minY: 20, maxX: 110, maxY: 70)]
        )
        fixture.controller.manager?.enqueue(diff: geoDiff)
        fixture.controller.commitDiffs()

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 0)
    }

    func test_commitDiffs_semanticUpdate_postsLayoutChanged() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let addDiff = makeDiff(added: [makeTextDiffNode(id: 1, label: "Before")])
        fixture.controller.manager?.enqueue(diff: addDiff)
        fixture.controller.commitDiffs()

        MockUIAccessibility.postedNotifications = []
        let updateDiff = makeSemanticUpdateDiff(
            rootID: 1,
            updates: [makeTextDiffNode(id: 1, label: "After")]
        )
        fixture.controller.manager?.enqueue(diff: updateDiff)
        fixture.controller.commitDiffs()

        XCTAssertEqual(MockUIAccessibility.postedNotifications.count, 1)
        XCTAssertEqual(MockUIAccessibility.postedNotifications.first?.notification, .layoutChanged)
    }

    // MARK: - accessibilityElements

    func test_accessibilityElements_forwardsFromManager() {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let diff = makeDiff(
            added: [makeTextDiffNode(id: 1, label: "Label")]
        )
        fixture.controller.manager?.enqueue(diff: diff)
        fixture.controller.commitDiffs()

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 1)
    }

    func test_accessibilityElements_emptyWhenOff() {
        let fixture = makeFixture()

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 0)
    }

    func test_accessibilityElements_emptyWhenAutomaticAndVoiceOverOff() {
        MockUIAccessibility.isVoiceOverRunning = false
        let fixture = makeFixture()
        fixture.controller.semantics = .automatic

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 0)
    }

    // MARK: - Diff Stream

    func test_diffStream_enqueuesDiffToManager() async {
        let fixture = makeFixture()
        fixture.controller.semantics = .on

        let diffProcessed = expectation(description: "diff processed")
        fixture.controller.onSemanticsDiffProcessedForTesting = {
            diffProcessed.fulfill()
        }

        let diff = makeDiff(
            added: [makeTextDiffNode(id: 1, label: "Streamed")]
        )

        fixture.stateMachineService.onSemanticsDiffReceived(
            fixture.stateMachine.stateMachineHandle,
            requestID: 1,
            diff: diff
        )
        await fulfillment(of: [diffProcessed], timeout: 1.0)

        fixture.controller.commitDiffs()

        XCTAssertEqual(fixture.controller.accessibilityElements.count, 1)
        XCTAssertEqual(fixture.controller.accessibilityElements.first?.accessibilityLabel, "Streamed")
    }

    // MARK: - Helpers

    private func makeFixture() -> Fixture {
        let commandQueue = MockCommandQueue()
        let messageGate = CommandQueueMessageGate(driver: commandQueue)
        let stateMachineService = StateMachineService(
            dependencies: .init(commandQueue: commandQueue, messageGate: messageGate)
        )
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123
        )

        let notificationCenter = MockNotificationCenter()
        let delegate = MockSemanticsControllerDelegate()
        let controller = SemanticsController(
            dependencies: .init(
                stateMachine: stateMachine,
                accessibility: MockUIAccessibility.self,
                notificationCenter: notificationCenter
            )
        )
        controller.delegate = delegate

        return Fixture(
            controller: controller,
            delegate: delegate,
            stateMachine: stateMachine,
            stateMachineService: stateMachineService,
            commandQueue: commandQueue,
            notificationCenter: notificationCenter
        )
    }

    private func makeTextDiffNode(id: UInt32, label: String) -> SemanticsDiffNode {
        SemanticsDiffNode(
            id: id, role: .text, label: label, value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50,
            parentID: -1, siblingIndex: 0
        )
    }

    private func makeDiff(
        rootID: UInt32 = 1,
        added: [SemanticsDiffNode] = []
    ) -> SemanticsDiff {
        SemanticsDiff(
            frameNumber: 1, treeVersion: 1, rootID: rootID,
            removed: [], added: added, moved: [],
            childrenUpdated: [], updatedSemantic: [], updatedGeometry: []
        )
    }

    private func makeGeometryDiff(
        rootID: UInt32,
        updates: [SemanticsBoundsUpdate]
    ) -> SemanticsDiff {
        SemanticsDiff(
            frameNumber: 1, treeVersion: 1, rootID: rootID,
            removed: [], added: [], moved: [],
            childrenUpdated: [], updatedSemantic: [], updatedGeometry: updates
        )
    }

    private func makeSemanticUpdateDiff(
        rootID: UInt32,
        updates: [SemanticsDiffNode]
    ) -> SemanticsDiff {
        SemanticsDiff(
            frameNumber: 1, treeVersion: 1, rootID: rootID,
            removed: [], added: [], moved: [],
            childrenUpdated: [], updatedSemantic: updates, updatedGeometry: []
        )
    }
}

// MARK: - Test Fixtures

private struct Fixture {
    let controller: SemanticsController
    let delegate: MockSemanticsControllerDelegate
    let stateMachine: StateMachine
    let stateMachineService: StateMachineService
    let commandQueue: MockCommandQueue
    let notificationCenter: MockNotificationCenter
}

private class MockSemanticsControllerDelegate: SemanticsControllerDelegate {
    var wakeRequestCount = 0
    var enableSemanticsCount = 0
    var container: AnyObject = NSObject()
    var displayScale: CGFloat = 1.0
    private var isModal = false

    func semanticsControllerDidRequestWake(_ controller: SemanticsController) {
        wakeRequestCount += 1
    }

    func semanticsControllerDidEnableSemantics(_ controller: SemanticsController) {
        enableSemanticsCount += 1
    }

    func semanticsController(_ controller: SemanticsController, didUpdateModalState isModal: Bool) -> Bool {
        let transitioned = self.isModal != isModal
        self.isModal = isModal
        return transitioned
    }

    func accessibilityContainerForSemanticsController(_ controller: SemanticsController) -> AnyObject {
        container
    }

    func displayScaleForSemanticsController(_ controller: SemanticsController) -> CGFloat {
        displayScale
    }
}

#endif
