//
//  CommandQueueMessageGate.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// Controls when the command queue's message pump is active.
///
/// The pump is a high-frequency timer that drains queued C++ messages on the
/// main thread. Keeping it armed when there is no work wastes CPU; leaving it
/// disarmed when there *is* work stalls callbacks. This type tracks two
/// independent sources of demand and arms/disarms the pump accordingly:
///
/// 1. **Immediate requests** — fire-and-forget commands that expect a callback
///    (file loads, artboard instantiations, etc.). Each request is tracked by
///    its `requestID`; the pump stays armed until every outstanding ID has been
///    retired via ``callbackProcessed(requestID:)``.
///
/// 2. **Frame drains** — per-display-link ticks that flush subscription updates
///    for active animations/state machines. These are coalesced so that at most
///    one drain is in flight per run-loop turn.
///
/// Once both sources are idle the pump is disarmed. Calling ``stop()``
/// hard-disables the gate so that late arrivals cannot re-arm the pump after
/// the runtime is meant to be quiescent.
@MainActor
final class CommandQueueMessageGate {
    private let messagePumpDriver: any _CommandQueueMessagePumpDriver
    private var pendingRequestIDs = Set<UInt64>()
    private var isFrameDrainActive = false
    private var didScheduleFrameDrainThisTurn = false
    private var isPumpActive = false
    private var isEnabled = true

    init(driver: any _CommandQueueMessagePumpDriver) {
        self.messagePumpDriver = driver
    }

    func processMessagesImmediately(requestID: UInt64) {
        guard isEnabled else {
            return
        }
        pendingRequestIDs.insert(requestID)
        startPumpIfNeeded()
    }

    func callbackProcessed(requestID: UInt64) {
        pendingRequestIDs.remove(requestID)
        stopPumpIfIdle()
    }

    func processMessagesForFrame(hasActiveListeners: Bool) {
        guard isEnabled else {
            return
        }
        guard hasActiveListeners else {
            return
        }
        guard !didScheduleFrameDrainThisTurn else {
            return
        }

        didScheduleFrameDrainThisTurn = true
        isFrameDrainActive = true
        startPumpIfNeeded()

        // Clean up at the tail of this run-loop turn so the pump stays armed
        // just long enough to process the current frame's messages, then
        // re-evaluates whether it should remain active.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.didScheduleFrameDrainThisTurn = false
            self.isFrameDrainActive = false
            self.stopPumpIfIdle()
        }
    }

    func stop() {
        isEnabled = false
        pendingRequestIDs.removeAll()
        isFrameDrainActive = false
        didScheduleFrameDrainThisTurn = false
        if isPumpActive {
            messagePumpDriver.stopMessageProcessing()
            isPumpActive = false
        }
    }

    private func startPumpIfNeeded() {
        guard isEnabled else {
            return
        }
        guard !isPumpActive else {
            return
        }
        messagePumpDriver.startMessageProcessing()
        isPumpActive = true
    }

    private func stopPumpIfIdle() {
        guard isPumpActive else {
            return
        }
        if pendingRequestIDs.isEmpty && !isFrameDrainActive {
            messagePumpDriver.stopMessageProcessing()
            isPumpActive = false
        }
    }
}
