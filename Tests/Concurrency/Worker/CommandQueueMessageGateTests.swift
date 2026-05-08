//
//  CommandQueueMessageGateTests.swift
//  RiveRuntimeTests
//
//  Created by AI Assistant on 4/8/26.
//

import XCTest
@testable import RiveRuntime

final class CommandQueueMessageGateTests: XCTestCase {
    /// Important because asset and state-machine requests can be issued in bursts.
    /// We must not start multiple message pumps for repeated immediate requests,
    /// or we introduce avoidable scheduler churn around view setup/advance.
    @MainActor
    func test_processMessagesImmediately_startsPumpOnlyOnceForBurstRequests() {
        let queue = MockCommandQueue()
        let gate = CommandQueueMessageGate(driver: queue)

        gate.processMessagesImmediately(requestID: 1)
        gate.processMessagesImmediately(requestID: 2)
        gate.processMessagesImmediately(requestID: 3)

        XCTAssertEqual(queue.startCalls.count, 1)
        XCTAssertEqual(queue.stopCalls.count, 0)
    }

    /// Important because multiple callbacks can complete out-of-order while the
    /// render loop is active. The pump must stay alive until all request IDs are
    /// retired, otherwise view-facing APIs can observe partial progress.
    @MainActor
    func test_callbackProcessed_stopsPumpOnlyAfterLastPendingRequest() {
        let queue = MockCommandQueue()
        let gate = CommandQueueMessageGate(driver: queue)

        gate.processMessagesImmediately(requestID: 10)
        gate.processMessagesImmediately(requestID: 20)
        XCTAssertEqual(queue.startCalls.count, 1)

        gate.callbackProcessed(requestID: 10)
        XCTAssertEqual(queue.stopCalls.count, 0)

        gate.callbackProcessed(requestID: 20)
        XCTAssertEqual(queue.stopCalls.count, 1)
    }

    /// Important for `RiveController` frame advance: each display frame can call
    /// `processMessagesForFrame`, but we only want one synchronous drain per
    /// run-loop turn to avoid redundant work when multiple views share a gate.
    @MainActor
    func test_processMessagesForFrame_coalescesRequestsWithinRunLoopTurn() async {
        let queue = MockCommandQueue()
        let gate = CommandQueueMessageGate(driver: queue)

        gate.processMessagesForFrame()
        gate.processMessagesForFrame()
        gate.processMessagesForFrame()

        XCTAssertEqual(queue.processMessagesCalls.count, 1)

        // Wait for the async reset scheduled by processMessagesForFrame.
        await Task.yield()

        // After reset, the next call should drain again.
        gate.processMessagesForFrame()
        XCTAssertEqual(queue.processMessagesCalls.count, 2)
    }

    /// Important for lifecycle transitions (e.g. controller/worker teardown).
    /// `stop()` must hard-disable pumping so late callbacks or frame ticks do not
    /// re-arm processing after the runtime is meant to be quiescent.
    @MainActor
    func test_stop_disablesFurtherPumpActivity() async {
        let queue = MockCommandQueue()
        let gate = CommandQueueMessageGate(driver: queue)

        gate.processMessagesImmediately(requestID: 1)
        XCTAssertEqual(queue.startCalls.count, 1)

        gate.stop()
        XCTAssertEqual(queue.stopCalls.count, 1)

        gate.processMessagesImmediately(requestID: 2)
        gate.processMessagesForFrame()

        await Task.yield()

        XCTAssertEqual(queue.startCalls.count, 1)
        XCTAssertEqual(queue.stopCalls.count, 1)
    }
}

