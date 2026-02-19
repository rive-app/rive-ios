//
//  ArtboardTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @preconcurrency @testable import RiveRuntime

/// Test suite for Artboard functionality.
///
/// This test class verifies the behavior of Artboard, which represents a Rive
/// artboard and provides access to its data and operations. The tests cover artboard
/// creation, equality comparison, state machine queries, and proper resource management.
///
/// Key areas tested:
/// - Artboard creation with dependencies and handles
/// - Equality comparison based on underlying artboard handles
/// - State machine name retrieval through the artboard service
/// - Proper dependency injection and service coordination
/// - Resource cleanup and memory management
class ArtboardTests: XCTestCase {
    @MainActor
    func test_equality_withSameArtboardHandle_returnsTrue() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard1 = Artboard(dependencies: dependencies, artboardHandle: 1)
        let artboard2 = Artboard(dependencies: dependencies, artboardHandle: 1)

        XCTAssertEqual(artboard1, artboard2)
    }

    @MainActor
    func test_equality_withDifferentArtboardHandles_returnsFalse() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard1 = Artboard(dependencies: dependencies, artboardHandle: 1)
        let artboard2 = Artboard(dependencies: dependencies, artboardHandle: 2)

        XCTAssertNotEqual(artboard1, artboard2)
    }

    // MARK: - State Machine Names Tests
    @MainActor
    func test_getStateMachineNames_withValidArtboardHandle_returnsStateMachineNames() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 1)

        // Mock the command queue to trigger the onStateMachineNamesListed callback
        let expectation = expectation(description: "state machine names received")
        mockCommandQueue.stubRequestStateMachineNames { artboardHandle, requestID in
            XCTAssertEqual(artboardHandle, 1)
            // Simulate the callback from the command queue
            artboardService.onStateMachineNamesListed(1, names: ["State Machine 1", "State Machine 2"], requestID: requestID)
            expectation.fulfill()
        }

        let stateMachineNames = try await artboard.getStateMachineNames()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(stateMachineNames, ["State Machine 1", "State Machine 2"])
    }

    @MainActor
    func test_getStateMachineNames_withEmptyStateMachineList_returnsEmptyArray() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 1)

        // Mock the command queue to trigger the onStateMachineNamesListed callback
        let expectation = expectation(description: "state machine names received")
        mockCommandQueue.stubRequestStateMachineNames { artboardHandle, requestID in
            XCTAssertEqual(artboardHandle, 1)
            // Simulate the callback from the command queue
            artboardService.onStateMachineNamesListed(1, names: [], requestID: requestID)
            expectation.fulfill()
        }

        let stateMachineNames = try await artboard.getStateMachineNames()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(stateMachineNames.isEmpty)
    }

    @MainActor
    func test_getStateMachineNames_passesCorrectArtboardHandle() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 42)

        // Mock the command queue to trigger the onStateMachineNamesListed callback
        let expectation = expectation(description: "state machine names received")
        mockCommandQueue.stubRequestStateMachineNames { artboardHandle, requestID in
            XCTAssertEqual(artboardHandle, 42)
            // Simulate the callback from the command queue
            artboardService.onStateMachineNamesListed(artboardHandle, names: ["Test State Machine"], requestID: requestID)
            expectation.fulfill()
        }

        _ = try await artboard.getStateMachineNames()
        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: - Default View Model Info Tests
    @MainActor
    func test_getDefaultViewModelInfo_withValidArtboardAndFile_returnsViewModelInfo() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 1)
        
        // Create a mock file with dependencies
        let (file, _, _, _) = File.mock(fileHandle: 123)

        // Mock the command queue to trigger the onDefaultViewModelInfoReceived callback
        let expectation = expectation(description: "default view model info received")
        mockCommandQueue.stubRequestDefaultViewModelInfo { artboardHandle, fileHandle, requestID in
            XCTAssertEqual(artboardHandle, 1)
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue
            artboardService.onDefaultViewModelInfoReceived(artboardHandle, requestID: requestID, viewModelName: "TestViewModel", instanceName: "TestInstance")
            expectation.fulfill()
        }

        let (viewModelName, instanceName) = try await artboard.getDefaultViewModelInfo(parent: file)
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(viewModelName, "TestViewModel")
        XCTAssertEqual(instanceName, "TestInstance")
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.first?.artboardHandle, 1)
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.first?.fileHandle, 123)
    }

    @MainActor
    func test_getDefaultViewModelInfo_passesCorrectArtboardAndFileHandles() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 42)
        
        // Create a mock file with dependencies
        let (file, _, _, _) = File.mock(fileHandle: 456)

        // Mock the command queue to verify correct handles are passed
        let expectation = expectation(description: "default view model info received")
        mockCommandQueue.stubRequestDefaultViewModelInfo { artboardHandle, fileHandle, requestID in
            XCTAssertEqual(artboardHandle, 42)
            XCTAssertEqual(fileHandle, 456)
            // Simulate the callback from the command queue
            artboardService.onDefaultViewModelInfoReceived(artboardHandle, requestID: requestID, viewModelName: "AnotherViewModel", instanceName: "AnotherInstance")
            expectation.fulfill()
        }

        _ = try await artboard.getDefaultViewModelInfo(parent: file)
        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createDefaultStateMachine_returnsStateMachineWithCorrectHandle() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 123)

        // Mock the command queue to return a specific state machine handle and capture the artboard handle
        var capturedArtboardHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultStateMachine { artboardHandle in
            capturedArtboardHandle = artboardHandle
            return 42 // Return a specific state machine handle
        }

        let stateMachine = try await artboard.createStateMachine()
        XCTAssertNotNil(stateMachine)
        XCTAssertEqual(capturedArtboardHandle, 123)
        XCTAssertEqual(stateMachine.stateMachineHandle, 42)
    }

    @MainActor
    func test_createStateMachineNamed_returnsStateMachineWithCorrectHandle() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 123)

        // Mock the command queue to return state machine names for validation
        let expectation = expectation(description: "state machine names received")
        mockCommandQueue.stubRequestStateMachineNames { artboardHandle, requestID in
            XCTAssertEqual(artboardHandle, 123)
            // Simulate the callback from the command queue
            artboardService.onStateMachineNamesListed(123, names: ["Test State Machine", "Another State Machine"], requestID: requestID)
            expectation.fulfill()
        }

        // Mock the command queue to return a specific state machine handle and capture parameters
        var capturedName: String = ""
        var capturedArtboardHandle: UInt64 = 0
        mockCommandQueue.stubCreateStateMachineNamed { name, artboardHandle in
            capturedName = name
            capturedArtboardHandle = artboardHandle
            return 42 // Return a specific state machine handle
        }

        let stateMachine = try await artboard.createStateMachine("Test State Machine")
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertNotNil(stateMachine)
        XCTAssertEqual(capturedName, "Test State Machine")
        XCTAssertEqual(capturedArtboardHandle, 123)
        XCTAssertEqual(stateMachine.stateMachineHandle, 42)
    }

    @MainActor
    func test_createStateMachineNamed_withInvalidName_throwsError() async throws {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 123)

        // Mock the command queue to return state machine names that don't include the requested name
        let expectation = expectation(description: "state machine names received")
        mockCommandQueue.stubRequestStateMachineNames { artboardHandle, requestID in
            XCTAssertEqual(artboardHandle, 123)
            // Simulate the callback from the command queue with names that don't include "Invalid Name"
            artboardService.onStateMachineNamesListed(123, names: ["Valid State Machine 1", "Valid State Machine 2"], requestID: requestID)
            expectation.fulfill()
        }

        do {
            _ = try await artboard.createStateMachine("Invalid Name")
            XCTFail("Expected ArtboardError.invalidStateMachine to be thrown")
        } catch ArtboardError.invalidStateMachine(let name) {
            XCTAssertEqual(name, "Invalid Name")
        } catch {
            XCTFail("Expected ArtboardError.invalidStateMachine, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_artboard_onDeinit_callsDelete() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let deleteArtboardExpectation = expectation(description: "delete artboard")
        let deleteArtboardListenerExpectation = expectation(description: "delete artboard listener")
        mockCommandQueue.stubDeleteArtboard { handle, requestID in
            XCTAssertEqual(handle, 1)
            XCTAssertTrue(
                mockCommandQueue.deleteArtboardListenerCalls.isEmpty,
                "Listener should not be removed before delete callback is received"
            )
            deleteArtboardExpectation.fulfill()
            artboardService.onArtboardDeleted(handle, requestID: requestID)
        }

        mockCommandQueue.stubDeleteArtboardListener { handle in
            XCTAssertEqual(handle, 1)
            deleteArtboardListenerExpectation.fulfill()
        }

        autoreleasepool {
            var artboard: Artboard? = Artboard(dependencies: dependencies, artboardHandle: 1)
            _ = artboard
            artboard = nil
        }

        wait(for: [deleteArtboardExpectation, deleteArtboardListenerExpectation])
        XCTAssertEqual(mockCommandQueue.deleteArtboardCalls.first?.artboardHandle, 1)
        XCTAssertEqual(mockCommandQueue.deleteArtboardListenerCalls.first?.artboardHandle, 1)
    }

    @MainActor
    func test_setSize_withDefaultScale_callsSetArtboardSize() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 42)
        let size = CGSize(width: 100, height: 200)

        artboard.setSize(size)

        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.artboardHandle, 42)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.width, 100)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.height, 200)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.scale, 1)
    }

    @MainActor
    func test_setSize_withCustomScale_callsSetArtboardSize() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 123)
        let size = CGSize(width: 500, height: 600)
        let scale: Float = 2.5

        artboard.setSize(size, scale: scale)

        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.artboardHandle, 123)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.width, 500)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.height, 600)
        XCTAssertEqual(mockCommandQueue.setArtboardSizeCalls.first?.scale, scale)
    }

    @MainActor
    func test_resetSize_callsResetArtboardSize() {
        let mockCommandQueue = MockCommandQueue()
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))

        let dependencies = Artboard.Dependencies(
            artboardService: artboardService
        )

        let artboard = Artboard(dependencies: dependencies, artboardHandle: 77)

        artboard.resetSize()

        XCTAssertEqual(mockCommandQueue.resetArtboardSizeCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.resetArtboardSizeCalls.first?.artboardHandle, 77)
    }


}
