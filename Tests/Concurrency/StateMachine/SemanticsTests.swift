//
//  SemanticsTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 4/20/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

class SemanticsTests: XCTestCase {

    // MARK: - Command Queue Forwarding

    @MainActor
    func test_enableSemantics_forwardsToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        stateMachine.enableSemantics()

        XCTAssertEqual(mockCommandQueue.enableSemanticsCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.enableSemanticsCalls.first?.stateMachineHandle, 123)
    }

    @MainActor
    func test_fireSemanticAction_forwardsAllParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        stateMachine.fireSemanticAction(nodeID: 42, actionType: .tap)

        XCTAssertEqual(mockCommandQueue.fireSemanticActionCalls.count, 1)
        let call = mockCommandQueue.fireSemanticActionCalls.first
        XCTAssertEqual(call?.stateMachineHandle, 123)
        XCTAssertEqual(call?.semanticNodeID, 42)
        XCTAssertEqual(call?.actionType, .tap)
    }

    @MainActor
    func test_fireSemanticAction_forwardsEachActionType() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        stateMachine.fireSemanticAction(nodeID: 1, actionType: .tap)
        stateMachine.fireSemanticAction(nodeID: 2, actionType: .increase)
        stateMachine.fireSemanticAction(nodeID: 3, actionType: .decrease)

        XCTAssertEqual(mockCommandQueue.fireSemanticActionCalls.count, 3)
        XCTAssertEqual(mockCommandQueue.fireSemanticActionCalls[0].actionType, .tap)
        XCTAssertEqual(mockCommandQueue.fireSemanticActionCalls[1].actionType, .increase)
        XCTAssertEqual(mockCommandQueue.fireSemanticActionCalls[2].actionType, .decrease)
    }

    @MainActor
    func test_requestSemanticFocus_forwardsAllParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        stateMachine.requestSemanticFocus(nodeID: 7)

        XCTAssertEqual(mockCommandQueue.requestSemanticFocusCalls.count, 1)
        let call = mockCommandQueue.requestSemanticFocusCalls.first
        XCTAssertEqual(call?.stateMachineHandle, 123)
        XCTAssertEqual(call?.semanticNodeID, 7)
    }

    // MARK: - AsyncStream Delivery

    @MainActor
    func test_semanticsDiffStream_emitsDiff_whenCallbackFires() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let diff = makeTestDiff(frameNumber: 10, treeVersion: 5, rootID: 1)

        let receivedExpectation = expectation(description: "semantics diff received")

        let stream = stateMachine.semanticsDiffStream()
        let task = Task {
            var iterator = stream.makeAsyncIterator()
            let received = await iterator.next()
            XCTAssertEqual(received?.frameNumber, 10)
            XCTAssertEqual(received?.treeVersion, 5)
            XCTAssertEqual(received?.rootID, 1)
            receivedExpectation.fulfill()
        }

        await Task.yield()
        stateMachineService.onSemanticsDiffReceived(123, requestID: 999, diff: diff)

        await fulfillment(of: [receivedExpectation], timeout: 1.0)
        task.cancel()
    }

    @MainActor
    func test_semanticsDiffStream_multipleSubscribers_allReceive() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let diff = makeTestDiff(frameNumber: 10, treeVersion: 5, rootID: 1)

        let expectationA = expectation(description: "subscriber A received")
        let expectationB = expectation(description: "subscriber B received")

        let streamA = stateMachine.semanticsDiffStream()
        let streamB = stateMachine.semanticsDiffStream()

        let taskA = Task {
            var iterator = streamA.makeAsyncIterator()
            _ = await iterator.next()
            expectationA.fulfill()
        }

        let taskB = Task {
            var iterator = streamB.makeAsyncIterator()
            _ = await iterator.next()
            expectationB.fulfill()
        }

        await Task.yield()
        stateMachineService.onSemanticsDiffReceived(123, requestID: 999, diff: diff)

        await fulfillment(of: [expectationA, expectationB], timeout: 1.0)
        taskA.cancel()
        taskB.cancel()
    }

    @MainActor
    func test_semanticsDiffStream_onlyEmitsForMatchingHandle() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachineA = StateMachine(dependencies: dependencies, stateMachineHandle: 100)

        let diff = makeTestDiff(frameNumber: 10, treeVersion: 5, rootID: 1)

        let shouldNotReceive = expectation(description: "should not receive")
        shouldNotReceive.isInverted = true

        let stream = stateMachineA.semanticsDiffStream()
        let task = Task {
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
            shouldNotReceive.fulfill()
        }

        await Task.yield()
        stateMachineService.onSemanticsDiffReceived(200, requestID: 999, diff: diff)

        await fulfillment(of: [shouldNotReceive], timeout: 0.5)
        task.cancel()
    }

    @MainActor
    func test_semanticsDiffStream_cancellationCleansUp() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let cleaned = expectation(description: "continuation removed")
        stateMachineService.onContinuationRemoved = { cleaned.fulfill() }

        let stream = stateMachine.semanticsDiffStream()
        let task = Task {
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
        }

        await Task.yield()
        XCTAssertTrue(stateMachine.hasActiveListeners)

        task.cancel()
        await fulfillment(of: [cleaned], timeout: 1.0)

        XCTAssertFalse(stateMachine.hasActiveListeners)
    }

    // MARK: - hasActiveListeners

    @MainActor
    func test_hasActiveListeners_includesSemanticsContinuations() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        XCTAssertFalse(stateMachine.hasActiveListeners)

        let stream = stateMachine.semanticsDiffStream()
        let task = Task {
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
        }

        await Task.yield()
        XCTAssertTrue(stateMachine.hasActiveListeners)

        task.cancel()
        await Task.yield()

        XCTAssertFalse(stateMachine.hasActiveListeners)
    }

    // MARK: - orderedOperations

    @MainActor
    func test_orderedOperations_returnsAllCategoriesInOrder() {
        let node = makeTestNode(nodeID: 1)
        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 0, minY: 0, maxX: 10, maxY: 10)
        let childrenUpdate = SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])

        let diff = SemanticsDiff(
            frameNumber: 1,
            treeVersion: 1,
            rootID: 0,
            removed: [NSNumber(value: 1)],
            added: [node],
            moved: [node],
            childrenUpdated: [childrenUpdate],
            updatedSemantic: [node],
            updatedGeometry: [boundsUpdate]
        )

        let ops = diff.orderedOperations
        XCTAssertEqual(ops.count, 6)

        guard case .removed = ops[0] else { return XCTFail("Expected .removed at index 0") }
        guard case .added = ops[1] else { return XCTFail("Expected .added at index 1") }
        guard case .moved = ops[2] else { return XCTFail("Expected .moved at index 2") }
        guard case .childrenUpdated = ops[3] else { return XCTFail("Expected .childrenUpdated at index 3") }
        guard case .updatedSemantic = ops[4] else { return XCTFail("Expected .updatedSemantic at index 4") }
        guard case .updatedGeometry = ops[5] else { return XCTFail("Expected .updatedGeometry at index 5") }
    }

    @MainActor
    func test_orderedOperations_omitsEmptyCategories() {
        let node = makeTestNode(nodeID: 1)
        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 0, minY: 0, maxX: 10, maxY: 10)

        let diff = SemanticsDiff(
            frameNumber: 1,
            treeVersion: 1,
            rootID: 0,
            removed: [],
            added: [node],
            moved: [],
            childrenUpdated: [],
            updatedSemantic: [],
            updatedGeometry: [boundsUpdate]
        )

        let ops = diff.orderedOperations
        XCTAssertEqual(ops.count, 2)

        guard case .added = ops[0] else { return XCTFail("Expected .added at index 0") }
        guard case .updatedGeometry = ops[1] else { return XCTFail("Expected .updatedGeometry at index 1") }
    }

    @MainActor
    func test_orderedOperations_emptyDiff_returnsEmptyArray() {
        let diff = SemanticsDiff(
            frameNumber: 1,
            treeVersion: 1,
            rootID: 0,
            removed: [],
            added: [],
            moved: [],
            childrenUpdated: [],
            updatedSemantic: [],
            updatedGeometry: []
        )

        XCTAssertTrue(diff.orderedOperations.isEmpty)
    }

    @MainActor
    func test_orderedOperations_preservesNodeData() {
        let node = SemanticsDiffNode(
            id: 42,
            role: .button,
            label: "Tap me",
            value: "On",
            hint: "Toggles",
            stateFlags: [.expanded, .focused],
            traitFlags: [.expandable, .focusable],
            headingLevel: 2,
            minX: 10,
            minY: 20,
            maxX: 100,
            maxY: 200,
            parentID: 5,
            siblingIndex: 3
        )

        let diff = SemanticsDiff(
            frameNumber: 1,
            treeVersion: 1,
            rootID: 0,
            removed: [],
            added: [node],
            moved: [],
            childrenUpdated: [],
            updatedSemantic: [],
            updatedGeometry: []
        )

        let ops = diff.orderedOperations
        guard case .added(let nodes) = ops.first else {
            return XCTFail("Expected .added operation")
        }

        XCTAssertEqual(nodes.count, 1)
        let addedNode = nodes[0]
        XCTAssertEqual(addedNode.nodeID, 42)
        XCTAssertEqual(addedNode.role, .button)
        XCTAssertEqual(addedNode.label, "Tap me")
        XCTAssertEqual(addedNode.value, "On")
        XCTAssertEqual(addedNode.hint, "Toggles")
        XCTAssertEqual(addedNode.stateFlags, [.expanded, .focused])
        XCTAssertEqual(addedNode.traitFlags, [.expandable, .focusable])
        XCTAssertEqual(addedNode.headingLevel, 2)
        XCTAssertEqual(addedNode.minX, 10)
        XCTAssertEqual(addedNode.minY, 20)
        XCTAssertEqual(addedNode.maxX, 100)
        XCTAssertEqual(addedNode.maxY, 200)
        XCTAssertEqual(addedNode.parentID, 5)
        XCTAssertEqual(addedNode.siblingIndex, 3)
    }

    // MARK: - ObjC Type Correctness

    @MainActor
    func test_semanticsDiffNode_storesAllProperties() {
        let node = SemanticsDiffNode(
            id: 99,
            role: .slider,
            label: "Volume",
            value: "50",
            hint: "Adjust volume",
            stateFlags: [.disabled, .focused],
            traitFlags: [.focusable, .enablable],
            headingLevel: 0,
            minX: 1.5,
            minY: 2.5,
            maxX: 3.5,
            maxY: 4.5,
            parentID: -1,
            siblingIndex: 0
        )

        XCTAssertEqual(node.nodeID, 99)
        XCTAssertEqual(node.role, .slider)
        XCTAssertEqual(node.label, "Volume")
        XCTAssertEqual(node.value, "50")
        XCTAssertEqual(node.hint, "Adjust volume")
        XCTAssertEqual(node.stateFlags, [.disabled, .focused])
        XCTAssertEqual(node.traitFlags, [.focusable, .enablable])
        XCTAssertEqual(node.headingLevel, 0)
        XCTAssertEqual(node.minX, 1.5)
        XCTAssertEqual(node.minY, 2.5)
        XCTAssertEqual(node.maxX, 3.5)
        XCTAssertEqual(node.maxY, 4.5)
        XCTAssertEqual(node.parentID, -1)
        XCTAssertEqual(node.siblingIndex, 0)
    }

    @MainActor
    func test_semanticsBoundsUpdate_storesAllProperties() {
        let update = SemanticsBoundsUpdate(id: 42, minX: 10, minY: 20, maxX: 30, maxY: 40)

        XCTAssertEqual(update.nodeID, 42)
        XCTAssertEqual(update.minX, 10)
        XCTAssertEqual(update.minY, 20)
        XCTAssertEqual(update.maxX, 30)
        XCTAssertEqual(update.maxY, 40)
    }

    @MainActor
    func test_semanticsChildrenUpdate_storesAllProperties() {
        let update = SemanticsChildrenUpdate(parentID: 5, childIDs: [NSNumber(value: 10), NSNumber(value: 20), NSNumber(value: 30)])

        XCTAssertEqual(update.parentID, 5)
        XCTAssertEqual(update.childIDs.count, 3)
        XCTAssertEqual(update.childIDs[0].uint32Value, 10)
        XCTAssertEqual(update.childIDs[1].uint32Value, 20)
        XCTAssertEqual(update.childIDs[2].uint32Value, 30)
    }

    @MainActor
    func test_semanticsDiff_storesAllProperties() {
        let node = makeTestNode(nodeID: 1)
        let boundsUpdate = SemanticsBoundsUpdate(id: 2, minX: 0, minY: 0, maxX: 10, maxY: 10)
        let childrenUpdate = SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])

        let diff = SemanticsDiff(
            frameNumber: 42,
            treeVersion: 7,
            rootID: 99,
            removed: [NSNumber(value: 5)],
            added: [node],
            moved: [node],
            childrenUpdated: [childrenUpdate],
            updatedSemantic: [node],
            updatedGeometry: [boundsUpdate]
        )

        XCTAssertEqual(diff.frameNumber, 42)
        XCTAssertEqual(diff.treeVersion, 7)
        XCTAssertEqual(diff.rootID, 99)
        XCTAssertEqual(diff.removed.count, 1)
        XCTAssertEqual(diff.removed.first?.uint32Value, 5)
        XCTAssertEqual(diff.added.count, 1)
        XCTAssertEqual(diff.moved.count, 1)
        XCTAssertEqual(diff.childrenUpdated.count, 1)
        XCTAssertEqual(diff.updatedSemantic.count, 1)
        XCTAssertEqual(diff.updatedGeometry.count, 1)
    }

    // MARK: - Helpers

    private func makeTestNode(nodeID: UInt32) -> SemanticsDiffNode {
        return SemanticsDiffNode(
            id: nodeID,
            role: .button,
            label: "Test",
            value: "",
            hint: "",
            stateFlags: [],
            traitFlags: [],
            headingLevel: 0,
            minX: 0,
            minY: 0,
            maxX: 10,
            maxY: 10,
            parentID: -1,
            siblingIndex: 0
        )
    }

    private func makeTestDiff(frameNumber: UInt64, treeVersion: UInt64, rootID: UInt32) -> SemanticsDiff {
        return SemanticsDiff(
            frameNumber: frameNumber,
            treeVersion: treeVersion,
            rootID: rootID,
            removed: [],
            added: [],
            moved: [],
            childrenUpdated: [],
            updatedSemantic: [],
            updatedGeometry: []
        )
    }
}
