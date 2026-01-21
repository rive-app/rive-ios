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

        mockCommandQueue.stubAdvanceStateMachine { stateMachineHandle, time, _ in
            capturedStateMachineHandle = stateMachineHandle
            capturedTime = time
            expectation.fulfill()
        }

        stateMachine.advance(by: 0.75)

        wait(for: [expectation])

        XCTAssertEqual(capturedStateMachineHandle, 123)
        XCTAssertEqual(capturedTime, 0.75)
    }

    @MainActor
    func test_bindViewModelInstance_callsServiceWithCorrectParameters() {
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

        let (file, _, _, _) = File.mock(fileHandle: 1)

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

        wait(for: [expectation])

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

        let expectation = expectation(description: "delete state machine")
        mockCommandQueue.stubDeleteStateMachine { handle in
            XCTAssertEqual(handle, 1)
            expectation.fulfill()
        }

        autoreleasepool {
            var stateMachine: StateMachine? = StateMachine(dependencies: dependencies, stateMachineHandle: 1)
            _ = stateMachine
            stateMachine = nil
        }

        wait(for: [expectation])
        XCTAssertEqual(mockCommandQueue.deleteStateMachineCalls.first?.stateMachineHandle, 1)
    }


}

