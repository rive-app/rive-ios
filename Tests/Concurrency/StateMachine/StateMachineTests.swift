//
//  StateMachineTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

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
    private func makeStateMachine(
        handle: StateMachine.StateMachineHandle,
        commandQueue: MockCommandQueue
    ) -> StateMachine {
        return makeStateMachineAndService(handle: handle, commandQueue: commandQueue).stateMachine
    }

    @MainActor
    private func makeStateMachineAndService(
        handle: StateMachine.StateMachineHandle,
        commandQueue: MockCommandQueue
    ) -> (stateMachine: StateMachine, service: StateMachineService) {
        let service = StateMachineService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        return (
            StateMachine(
                dependencies: .init(stateMachineService: service),
                stateMachineHandle: handle
            ),
            service
        )
    }

    @MainActor
    private func makeViewModelInstance(
        handle: ViewModelInstance.ViewModelInstanceHandle,
        commandQueue: MockCommandQueue
    ) -> ViewModelInstance {
        let service = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        return ViewModelInstance(
            handle: handle,
            dependencies: .init(viewModelInstanceService: service)
        )
    }

    @MainActor
    func test_advance_callsServiceWithCorrectParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))

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
    func test_bindViewModelInstance_appliesMainBinding() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(handle: 123, commandQueue: mockCommandQueue)
        let viewModelInstance = makeViewModelInstance(handle: 456, commandQueue: mockCommandQueue)

        stateMachine.bindViewModelInstance(viewModelInstance)

        XCTAssertTrue(mockCommandQueue.bindViewModelInstanceCalls.isEmpty)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 456)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.bindCalls.first?.stateMachineHandle, 123)
        XCTAssertTrue(stateMachine.mainBinding === viewModelInstance)
    }

    @MainActor
    func test_setViewModelInstance_callsCommandQueueWithCorrectParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        stateMachineService.setViewModelInstance(123, to: 456)

        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 456)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.requestID, 0)
    }

    @MainActor
    func test_mainViewModelInstance_returnsReceivedHandle() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )
        let observer = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        mockCommandQueue.stubMainViewModelInstance { stateMachineHandle, receivedObserver, requestID in
            XCTAssertEqual(stateMachineHandle, 123)
            XCTAssertTrue((receivedObserver as AnyObject) === observer)
            stateMachineService.onViewModelInstanceReceived(
                stateMachineHandle,
                requestID: requestID,
                viewModelInstanceHandle: 789
            )
            return 456
        }

        let handle = try await stateMachineService.mainViewModelInstance(
            for: 123,
            observer: observer
        )

        XCTAssertEqual(handle, 789)
        XCTAssertEqual(mockCommandQueue.mainViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.mainViewModelInstanceCalls.first?.requestID, 0)
    }

    @MainActor
    func test_mainViewModelInstance_withServerError_throwsStateMachineError() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )
        let observer = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        mockCommandQueue.stubMainViewModelInstance { stateMachineHandle, _, requestID in
            stateMachineService.onStateMachineError(
                stateMachineHandle,
                requestID: requestID,
                message: "No main view model instance"
            )
            return 456
        }

        do {
            _ = try await stateMachineService.mainViewModelInstance(
                for: 123,
                observer: observer
            )
            XCTFail("Expected StateMachineError.error to be thrown")
        } catch let error as StateMachineError {
            guard case .error = error else {
                XCTFail("Expected StateMachineError.error, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected StateMachineError.error, got \(type(of: error)): \(error)")
        }

        XCTAssertTrue(mockCommandQueue.deleteViewModelInstanceCalls.isEmpty)
        XCTAssertEqual(mockCommandQueue.deleteViewModelInstanceListenerCalls.map(\.viewModelInstanceHandle), [456])
    }

    @MainActor
    func test_setGlobalViewModelInstance_callsCommandQueueWithCorrectParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        stateMachineService.setGlobalViewModelInstance(
            123,
            named: "Theme",
            to: 456
        )

        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.name, "Theme")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.viewModelInstanceHandle, 456)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.requestID, 0)
    }

    @MainActor
    func test_globalViewModelInstance_returnsReceivedHandle() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )
        let observer = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        mockCommandQueue.stubGlobalViewModelInstance { stateMachineHandle, name, receivedObserver, requestID in
            XCTAssertEqual(stateMachineHandle, 123)
            XCTAssertEqual(name, "Theme")
            XCTAssertTrue((receivedObserver as AnyObject) === observer)
            stateMachineService.onViewModelInstanceReceived(
                stateMachineHandle,
                requestID: requestID,
                viewModelInstanceHandle: 789
            )
            return 456
        }

        let handle = try await stateMachineService.globalViewModelInstance(
            for: 123,
            named: "Theme",
            observer: observer
        )

        XCTAssertEqual(handle, 789)
        XCTAssertEqual(mockCommandQueue.globalViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.globalViewModelInstanceCalls.first?.requestID, 0)
    }

    @MainActor
    func test_globalViewModelInstance_withServerError_throwsStateMachineError() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )
        let observer = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        mockCommandQueue.stubGlobalViewModelInstance { stateMachineHandle, _, _, requestID in
            stateMachineService.onStateMachineError(
                stateMachineHandle,
                requestID: requestID,
                message: "No matching global view model instance"
            )
            return 456
        }

        do {
            _ = try await stateMachineService.globalViewModelInstance(
                for: 123,
                named: "Unknown",
                observer: observer
            )
            XCTFail("Expected StateMachineError.error to be thrown")
        } catch let error as StateMachineError {
            guard case .error = error else {
                XCTFail("Expected StateMachineError.error, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected StateMachineError.error, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_setGlobalViewModelInstance_withServerError_logsError() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )
        let logger = StateMachineErrorLogger()
        RiveLog.logger = logger
        defer { RiveLog.logger = RiveLog.none }

        mockCommandQueue.stubSetGlobalViewModelInstance { stateMachineHandle, _, _, requestID in
            stateMachineService.onStateMachineError(
                stateMachineHandle,
                requestID: requestID,
                message: "Invalid global view model name"
            )
        }

        stateMachineService.setGlobalViewModelInstance(
            123,
            named: "Unknown",
            to: 456
        )
        await Task.yield()

        XCTAssertEqual(logger.errorTags, [.stateMachine])
    }

    @MainActor
    func test_bind_callsCommandQueueWithCorrectParameters() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                messageGate: CommandQueueMessageGate(driver: mockCommandQueue)
            )
        )

        stateMachineService.bind(123)

        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.bindCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.bindCalls.first?.requestID, 0)
    }

    @MainActor
    func test_stateMachine_onDeinit_callsDelete() {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))

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

    // MARK: - Cancellation

    @MainActor
    func test_deleteStateMachine_whenCancelled_throwsCancelledError() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        mockCommandQueue.stubDeleteStateMachine { handle in
            enteredContinuation.fulfill()
        }

        let task = Task { @MainActor in
            try await stateMachineService.deleteStateMachine(123)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected StateMachineError.cancelled to be thrown")
        } catch let error as StateMachineError {
            guard case .cancelled = error else {
                XCTFail("Expected StateMachineError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected StateMachineError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Streams

    @MainActor
    func test_settledStream_emitsVoid_whenStateMachineSettles() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
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
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
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

private final class StateMachineErrorLogger: RiveLog.Logger, @unchecked Sendable {
    private let lock = NSLock()
    private var _errorTags: [RiveLog.Tag] = []

    var errorTags: [RiveLog.Tag] {
        lock.withLock { _errorTags }
    }

    func notice(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
    func debug(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
    func trace(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
    func info(tag: RiveLog.Tag, _ message: @escaping () -> String) {}

    func error(tag: RiveLog.Tag, error: (any Error)?, _ message: @escaping () -> String) {
        lock.withLock {
            _errorTags.append(tag)
        }
    }

    func warning(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
    func fault(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
    func critical(tag: RiveLog.Tag, _ message: @escaping () -> String) {}
}
