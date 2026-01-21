//
//  InputHandlerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
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
        
        mockCommandQueue.stubPointerMove { stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID in
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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
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
        
        mockCommandQueue.stubPointerDown { stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID in
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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
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
        
        mockCommandQueue.stubPointerUp { stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID in
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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
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
        
        mockCommandQueue.stubPointerExit { stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID in
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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 111)
        
        let inputHandler = InputHandler(dependencies: .init(commandQueue: mockCommandQueue))
        
        let pointerEvent = PointerEvent(
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
}

