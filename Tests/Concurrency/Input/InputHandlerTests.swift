//
//  InputHandlerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

/// Test suite for InputHandler functionality.
///
/// This test class verifies the behavior of InputHandler, which handles pointer events
/// and forwards them to the command queue. The tests cover all pointer event types:
/// pointerMove, pointerDown, pointerUp, and pointerExit.
///
/// Key areas tested:
/// - Correct forwarding of pointer events to command queue
/// - Proper argument passing (position, bounds, fit, alignment, scaleFactor)
/// - Correct state machine handle usage
/// - Request ID generation and usage
class InputHandlerTests: XCTestCase {
    
    @MainActor
    func test_handle_pointerMove_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 123)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let expectation = expectation(description: "pointerMove called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedPosition: CGPoint = .zero
        var capturedScreenBounds: CGSize = .zero
        var capturedFit: RiveConfigurationFit = .none
        var capturedAlignment: RiveConfigurationAlignment = .center
        var capturedScaleFactor: Float = 0
        var capturedRequestID: UInt64 = 0
        
        mockCommandQueue.stubPointerMove { stateMachineHandle, id, position, screenBounds, fit, alignment, scaleFactor, requestID in
            capturedStateMachineHandle = stateMachineHandle
            capturedPosition = position
            capturedScreenBounds = screenBounds
            capturedFit = fit
            capturedAlignment = alignment
            capturedScaleFactor = scaleFactor
            capturedRequestID = requestID
            expectation.fulfill()
        }
        
        let pointerEvent = PointerEvent(
            id: "touch-1",
            position: CGPoint(x: 100, y: 200),
            bounds: CGSize(width: 800, height: 600),
            fit: .contain,
            alignment: .topLeft,
            scaleFactor: 2.0
        )
        
        inputHandler.handle(.pointerMove(pointerEvent), in: stateMachine)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(capturedStateMachineHandle, 123)
        XCTAssertEqual(capturedPosition.x, 100)
        XCTAssertEqual(capturedPosition.y, 200)
        XCTAssertEqual(capturedScreenBounds.width, 800)
        XCTAssertEqual(capturedScreenBounds.height, 600)
        XCTAssertEqual(capturedFit, .contain)
        XCTAssertEqual(capturedAlignment, .topLeft)
        XCTAssertEqual(capturedScaleFactor, 2.0)
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.position.x, 100)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.position.y, 200)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.screenBounds.width, 800)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.screenBounds.height, 600)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.fit, .contain)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.alignment, .topLeft)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.scaleFactor, 2.0)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.first?.requestID, capturedRequestID)
    }
    
    @MainActor
    func test_handle_pointerDown_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 456)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let expectation = expectation(description: "pointerDown called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedPosition: CGPoint = .zero
        var capturedScreenBounds: CGSize = .zero
        var capturedFit: RiveConfigurationFit = .none
        var capturedAlignment: RiveConfigurationAlignment = .center
        var capturedScaleFactor: Float = 0
        var capturedRequestID: UInt64 = 0
        
        mockCommandQueue.stubPointerDown { stateMachineHandle, id, position, screenBounds, fit, alignment, scaleFactor, requestID in
            capturedStateMachineHandle = stateMachineHandle
            capturedPosition = position
            capturedScreenBounds = screenBounds
            capturedFit = fit
            capturedAlignment = alignment
            capturedScaleFactor = scaleFactor
            capturedRequestID = requestID
            expectation.fulfill()
        }
        
        let pointerEvent = PointerEvent(
            id: "touch-2",
            position: CGPoint(x: 250, y: 350),
            bounds: CGSize(width: 1024, height: 768),
            fit: .cover,
            alignment: .center,
            scaleFactor: 1.5
        )
        
        inputHandler.handle(.pointerDown(pointerEvent), in: stateMachine)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(capturedStateMachineHandle, 456)
        XCTAssertEqual(capturedPosition.x, 250)
        XCTAssertEqual(capturedPosition.y, 350)
        XCTAssertEqual(capturedScreenBounds.width, 1024)
        XCTAssertEqual(capturedScreenBounds.height, 768)
        XCTAssertEqual(capturedFit, .cover)
        XCTAssertEqual(capturedAlignment, .center)
        XCTAssertEqual(capturedScaleFactor, 1.5)
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.stateMachineHandle, 456)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.position.x, 250)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.position.y, 350)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.screenBounds.width, 1024)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.screenBounds.height, 768)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.fit, .cover)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.alignment, .center)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.scaleFactor, 1.5)
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.first?.requestID, capturedRequestID)
    }
    
    @MainActor
    func test_handle_pointerUp_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 789)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let expectation = expectation(description: "pointerUp called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedPosition: CGPoint = .zero
        var capturedScreenBounds: CGSize = .zero
        var capturedFit: RiveConfigurationFit = .none
        var capturedAlignment: RiveConfigurationAlignment = .center
        var capturedScaleFactor: Float = 0
        var capturedRequestID: UInt64 = 0
        
        mockCommandQueue.stubPointerUp { stateMachineHandle, id, position, screenBounds, fit, alignment, scaleFactor, requestID in
            capturedStateMachineHandle = stateMachineHandle
            capturedPosition = position
            capturedScreenBounds = screenBounds
            capturedFit = fit
            capturedAlignment = alignment
            capturedScaleFactor = scaleFactor
            capturedRequestID = requestID
            expectation.fulfill()
        }
        
        let pointerEvent = PointerEvent(
            id: "touch-3",
            position: CGPoint(x: 500, y: 400),
            bounds: CGSize(width: 1920, height: 1080),
            fit: .fitWidth,
            alignment: .bottomRight,
            scaleFactor: 3.0
        )
        
        inputHandler.handle(.pointerUp(pointerEvent), in: stateMachine)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(capturedStateMachineHandle, 789)
        XCTAssertEqual(capturedPosition.x, 500)
        XCTAssertEqual(capturedPosition.y, 400)
        XCTAssertEqual(capturedScreenBounds.width, 1920)
        XCTAssertEqual(capturedScreenBounds.height, 1080)
        XCTAssertEqual(capturedFit, .fitWidth)
        XCTAssertEqual(capturedAlignment, .bottomRight)
        XCTAssertEqual(capturedScaleFactor, 3.0)
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.stateMachineHandle, 789)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.position.x, 500)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.position.y, 400)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.screenBounds.width, 1920)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.screenBounds.height, 1080)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.fit, .fitWidth)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.alignment, .bottomRight)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.scaleFactor, 3.0)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.requestID, capturedRequestID)
    }
    
    @MainActor
    func test_handle_pointerExit_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 999)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let expectation = expectation(description: "pointerExit called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedPosition: CGPoint = .zero
        var capturedScreenBounds: CGSize = .zero
        var capturedFit: RiveConfigurationFit = .none
        var capturedAlignment: RiveConfigurationAlignment = .center
        var capturedScaleFactor: Float = 0
        var capturedRequestID: UInt64 = 0
        
        mockCommandQueue.stubPointerExit { stateMachineHandle, id, position, screenBounds, fit, alignment, scaleFactor, requestID in
            capturedStateMachineHandle = stateMachineHandle
            capturedPosition = position
            capturedScreenBounds = screenBounds
            capturedFit = fit
            capturedAlignment = alignment
            capturedScaleFactor = scaleFactor
            capturedRequestID = requestID
            expectation.fulfill()
        }
        
        let pointerEvent = PointerEvent(
            id: "touch-4",
            position: CGPoint(x: 0, y: 0),
            bounds: CGSize(width: 640, height: 480),
            fit: .none,
            alignment: .topCenter,
            scaleFactor: 1.0
        )
        
        inputHandler.handle(.pointerExit(pointerEvent), in: stateMachine)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(capturedStateMachineHandle, 999)
        XCTAssertEqual(capturedPosition.x, 0)
        XCTAssertEqual(capturedPosition.y, 0)
        XCTAssertEqual(capturedScreenBounds.width, 640)
        XCTAssertEqual(capturedScreenBounds.height, 480)
        XCTAssertEqual(capturedFit, .none)
        XCTAssertEqual(capturedAlignment, .topCenter)
        XCTAssertEqual(capturedScaleFactor, 1.0)
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.stateMachineHandle, 999)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.position.x, 0)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.position.y, 0)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.screenBounds.width, 640)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.screenBounds.height, 480)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.fit, RiveConfigurationFit.none)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.alignment, .topCenter)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.scaleFactor, 1.0)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.requestID, capturedRequestID)
    }
    
    @MainActor
    func test_handle_multipleEvents_usesDifferentRequestIDs() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 111)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let pointerEvent = PointerEvent(
            id: "touch-multi",
            position: CGPoint(x: 100, y: 100),
            bounds: CGSize(width: 800, height: 600),
            fit: .contain,
            alignment: .center,
            scaleFactor: 1.0
        )
        
        // Call multiple events
        inputHandler.handle(.pointerDown(pointerEvent), in: stateMachine)
        inputHandler.handle(.pointerMove(pointerEvent), in: stateMachine)
        inputHandler.handle(.pointerUp(pointerEvent), in: stateMachine)
        inputHandler.handle(.pointerExit(pointerEvent), in: stateMachine)
        
        // Verify all events were called
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerMoveCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.count, 1)
        
        // Verify that each call has a unique request ID
        let requestIDs = [
            mockCommandQueue.pointerDownCalls.first?.requestID,
            mockCommandQueue.pointerMoveCalls.first?.requestID,
            mockCommandQueue.pointerUpCalls.first?.requestID,
            mockCommandQueue.pointerExitCalls.first?.requestID
        ].compactMap { $0 }
        
        // All request IDs should be unique
        XCTAssertEqual(Set(requestIDs).count, 4, "All request IDs should be unique")
    }
    
    // MARK: - Pointer ID Pool Tests
    
    @MainActor
    func test_handle_sameTouchAcrossEvents_usesStablePoolID() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let event = makePointerEvent(id: "touch-A")
        
        XCTAssertTrue(inputHandler.handle(.pointerDown(event), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerMove(event), in: stateMachine))
        
        let downID = mockCommandQueue.pointerDownCalls.first?.id
        let moveID = mockCommandQueue.pointerMoveCalls.first?.id
        
        XCTAssertNotNil(downID)
        XCTAssertEqual(downID, moveID, "Same touch should reuse the same pool ID across events")
    }
    
    @MainActor
    func test_handle_duplicateEventType_reusesSamePoolID() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let downEvent = makePointerEvent(id: "touch-down")
        let moveEvent = makePointerEvent(id: "touch-move")
        let upEvent = makePointerEvent(id: "touch-up")
        let exitEvent = makePointerEvent(id: "touch-exit")
        
        XCTAssertTrue(inputHandler.handle(.pointerDown(downEvent), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerDown(downEvent), in: stateMachine))
        let firstDownID = mockCommandQueue.pointerDownCalls[0].id
        let secondDownID = mockCommandQueue.pointerDownCalls[1].id
        XCTAssertEqual(firstDownID, secondDownID, "Duplicate pointerDown should reuse the same pool ID")
        
        XCTAssertTrue(inputHandler.handle(.pointerMove(moveEvent), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerMove(moveEvent), in: stateMachine))
        let firstMoveID = mockCommandQueue.pointerMoveCalls[0].id
        let secondMoveID = mockCommandQueue.pointerMoveCalls[1].id
        XCTAssertEqual(firstMoveID, secondMoveID, "Duplicate pointerMove should reuse the same pool ID")
        
        XCTAssertTrue(inputHandler.handle(.pointerUp(upEvent), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerUp(upEvent), in: stateMachine))
        let firstUpID = mockCommandQueue.pointerUpCalls[0].id
        let secondUpID = mockCommandQueue.pointerUpCalls[1].id
        XCTAssertEqual(firstUpID, secondUpID, "Duplicate pointerUp should reuse the same pool ID")
        
        XCTAssertTrue(inputHandler.handle(.pointerExit(exitEvent), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerExit(exitEvent), in: stateMachine))
        let firstExitID = mockCommandQueue.pointerExitCalls[0].id
        let secondExitID = mockCommandQueue.pointerExitCalls[1].id
        XCTAssertEqual(firstExitID, secondExitID, "Duplicate pointerExit should reuse the same pool ID")
    }
    
    @MainActor
    func test_handle_differentTouches_assignDifferentPoolIDs() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let eventA = makePointerEvent(id: "touch-A")
        let eventB = makePointerEvent(id: "touch-B")
        
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventA), in: stateMachine))
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventB), in: stateMachine))
        
        let idA = mockCommandQueue.pointerDownCalls[0].id
        let idB = mockCommandQueue.pointerDownCalls[1].id
        
        XCTAssertNotEqual(idA, idB, "Different touches should receive different pool IDs")
    }
    
    @MainActor
    func test_handle_pointerUp_releasesPoolID() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let eventA = makePointerEvent(id: "touch-A")
        
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventA), in: stateMachine))
        let originalID = mockCommandQueue.pointerDownCalls.first?.id
        
        XCTAssertTrue(inputHandler.handle(.pointerUp(eventA), in: stateMachine))
        XCTAssertEqual(mockCommandQueue.pointerUpCalls.first?.id, originalID)
        
        let eventB = makePointerEvent(id: "touch-B")
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventB), in: stateMachine))
        
        let reusedID = mockCommandQueue.pointerDownCalls[1].id
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 2)
        XCTAssertEqual(reusedID, originalID,
                       "New touch should reuse the pool ID freed by pointerUp")
    }
    
    @MainActor
    func test_handle_pointerExit_releasesPoolID() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let eventA = makePointerEvent(id: "touch-A")
        
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventA), in: stateMachine))
        let originalID = mockCommandQueue.pointerDownCalls.first?.id
        
        XCTAssertTrue(inputHandler.handle(.pointerExit(eventA), in: stateMachine))
        XCTAssertEqual(mockCommandQueue.pointerExitCalls.first?.id, originalID)
        
        let eventB = makePointerEvent(id: "touch-B")
        XCTAssertTrue(inputHandler.handle(.pointerDown(eventB), in: stateMachine))
        
        let reusedID = mockCommandQueue.pointerDownCalls[1].id
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 2)
        XCTAssertEqual(reusedID, originalID,
                       "New touch should reuse the pool ID freed by pointerExit")
    }
    
    @MainActor
    func test_handle_pointerExitWithoutPriorDown_upsertsAndReleasesPoolID() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        let event = makePointerEvent(id: "touch-cancelled")
        
        XCTAssertTrue(inputHandler.handle(.pointerExit(event), in: stateMachine),
                      "Exit without prior down should still succeed via upsert")
        let exitID = mockCommandQueue.pointerExitCalls.first?.id
        
        let newEvent = makePointerEvent(id: "touch-new")
        XCTAssertTrue(inputHandler.handle(.pointerDown(newEvent), in: stateMachine))
        let reusedID = mockCommandQueue.pointerDownCalls.first?.id
        XCTAssertEqual(reusedID, exitID,
                       "New touch should reuse the pool ID freed by exit")
    }
    
    @MainActor
    func test_handle_poolExhaustion_returnsFalse() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        
        // Exhaust all 10 pool slots
        for i in 0..<10 {
            let event = makePointerEvent(id: "touch-\(i)")
            let result = inputHandler.handle(.pointerDown(event), in: stateMachine)
            XCTAssertTrue(result)
        }
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 10)
        
        // 11th touch should fail
        let overflow = makePointerEvent(id: "touch-overflow")
        let result = inputHandler.handle(.pointerDown(overflow), in: stateMachine)
        
        XCTAssertFalse(result, "Should return false when pool is exhausted")
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 10,
                       "Should not send event when pool is exhausted")
    }
    
    @MainActor
    func test_handle_poolExhaustion_succeedsAfterRelease() {
        let (inputHandler, mockCommandQueue, stateMachine) = makeFixture()
        
        // Exhaust all 10 pool slots
        for i in 0..<10 {
            let event = makePointerEvent(id: "touch-\(i)")
            inputHandler.handle(.pointerDown(event), in: stateMachine)
        }
        
        // Release one slot
        let releaseEvent = makePointerEvent(id: "touch-0")
        XCTAssertTrue(inputHandler.handle(.pointerUp(releaseEvent), in: stateMachine))
        
        // New touch should now succeed
        let newEvent = makePointerEvent(id: "touch-new")
        let result = inputHandler.handle(.pointerDown(newEvent), in: stateMachine)
        
        XCTAssertTrue(result, "Should succeed after a pool slot is freed")
        XCTAssertEqual(mockCommandQueue.pointerDownCalls.count, 11)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeFixture(stateMachineHandle: UInt64 = 1) -> (InputHandler, MockCommandQueue, StateMachine) {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: stateMachineHandle
        )
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        return (inputHandler, mockCommandQueue, stateMachine)
    }
    
    private func makePointerEvent(id: AnyHashable) -> PointerEvent {
        PointerEvent(
            id: id,
            position: .zero,
            bounds: CGSize(width: 100, height: 100),
            fit: .contain,
            alignment: .center,
            scaleFactor: 1.0
        )
    }
}

