//
//  StateMachineTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @preconcurrency @testable import RiveRuntime

/// Test suite for StateMachine functionality.
///
/// This test class verifies the behavior of StateMachine, which represents a Rive
/// state machine and provides access to its operations. The tests cover state machine
/// creation, advancement, view model binding, and proper resource management.
///
/// Key areas tested:
/// - State machine creation with dependencies and handles
/// - State machine advancement through the service
/// - View model instance binding through the service
/// - Proper dependency injection and service coordination
/// - Resource cleanup and memory management
class StateMachineTests: XCTestCase {
    @MainActor
    func test_advance_callsServiceWithCorrectParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )

        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let expectation = expectation(description: "advanceStateMachine called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedTime: TimeInterval = 0
        var capturedRequestID: UInt64 = 0

        mockCommandQueue.stubAdvanceStateMachine { stateMachineHandle, time, requestID in
            capturedStateMachineHandle = stateMachineHandle
            capturedTime = time
            capturedRequestID = requestID
            expectation.fulfill()
        }

        stateMachine.advance(by: 0.75)

        wait(for: [expectation])

        XCTAssertEqual(capturedStateMachineHandle, 123)
        XCTAssertEqual(capturedTime, 0.75)
        XCTAssertEqual(capturedRequestID, mockCommandQueue.advanceStateMachineCalls.first?.requestID)
    }

    @MainActor
    func test_bindViewModelInstance_callsServiceWithCorrectParameters() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))

        let stateMachineDependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )

        let viewModelInstanceDependencies = ViewModelInstance.Dependencies(
            viewModelInstanceService: viewModelInstanceService
        )

        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 123)

        // Create a mock ViewModelInstance with a known handle
        mockCommandQueue.stubCreateBlankViewModelInstance { _, _, _, _ in
            return 456
        }

        let (file, _, _, _) = await File.mock(fileHandle: 1)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 789)
        let viewModelInstance = ViewModelInstance(for: artboard, from: file, dependencies: viewModelInstanceDependencies)

        let expectation = expectation(description: "bindViewModelInstance called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedViewModelInstanceHandle: UInt64 = 0

        mockCommandQueue.stubBindViewModelInstance { stateMachineHandle, viewModelInstanceHandle, _ in
            capturedStateMachineHandle = stateMachineHandle
            capturedViewModelInstanceHandle = viewModelInstanceHandle
            expectation.fulfill()
        }

        stateMachine.bindViewModelInstance(viewModelInstance)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(capturedStateMachineHandle, 123)
        XCTAssertEqual(capturedViewModelInstanceHandle, 456)

        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.bindViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.bindViewModelInstanceCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.bindViewModelInstanceCalls.first?.viewModelInstanceHandle, 456)
    }

    @MainActor
    func test_stateMachine_onDeinit_callsDelete() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = StateMachine.Dependencies(
            stateMachineService: stateMachineService
        )

        let deleteStateMachineExpectation = expectation(description: "delete state machine")
        let deleteStateMachineListenerExpectation = expectation(description: "delete state machine listener")
        mockCommandQueue.stubDeleteStateMachine { handle in
            XCTAssertEqual(handle, 1)
            XCTAssertTrue(
                mockCommandQueue.deleteStateMachineListenerCalls.isEmpty,
                "Listener should not be removed before delete callback is received"
            )
            deleteStateMachineExpectation.fulfill()
            guard let requestID = mockCommandQueue.deleteStateMachineCalls.last?.requestID else {
                XCTFail("Expected deleteStateMachine call to be tracked before stub callback")
                return
            }
            stateMachineService.onStateMachineDeleted(handle, requestID: requestID)
        }

        mockCommandQueue.stubDeleteStateMachineListener { handle in
            XCTAssertEqual(handle, 1)
            deleteStateMachineListenerExpectation.fulfill()
        }

        autoreleasepool {
            var stateMachine: StateMachine? = StateMachine(dependencies: dependencies, stateMachineHandle: 1)
            _ = stateMachine
            stateMachine = nil
        }

        wait(for: [deleteStateMachineExpectation, deleteStateMachineListenerExpectation])
        XCTAssertEqual(mockCommandQueue.deleteStateMachineCalls.first?.stateMachineHandle, 1)
        XCTAssertEqual(mockCommandQueue.deleteStateMachineListenerCalls.first?.stateMachineHandle, 1)
    }

    @MainActor
    func test_settledStream_emitsVoid_whenStateMachineSettles() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let settledExpectation = expectation(description: "settled stream emits")

        let stream = stateMachine.settledStream()
        let waitForSettledTask = Task {
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
            settledExpectation.fulfill()
        }

        await Task.yield()
        stateMachineService.onStateMachineSettled(123, requestID: 999)

        await fulfillment(of: [settledExpectation], timeout: 1.0)
        waitForSettledTask.cancel()
    }

    @MainActor
    func test_settledStream_withMultipleSubscribers_emitsToAll() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue))
        let dependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: dependencies, stateMachineHandle: 123)

        let settledAExpectation = expectation(description: "settled stream A emits")
        let settledBExpectation = expectation(description: "settled stream B emits")

        let streamA = stateMachine.settledStream()
        let streamB = stateMachine.settledStream()

        let waitForSettledATask = Task {
            var iterator = streamA.makeAsyncIterator()
            _ = await iterator.next()
            settledAExpectation.fulfill()
        }

        let waitForSettledBTask = Task {
            var iterator = streamB.makeAsyncIterator()
            _ = await iterator.next()
            settledBExpectation.fulfill()
        }

        await Task.yield()
        stateMachineService.onStateMachineSettled(123, requestID: 999)

        await fulfillment(of: [settledAExpectation, settledBExpectation], timeout: 1.0)
        waitForSettledATask.cancel()
        waitForSettledBTask.cancel()
    }


}

