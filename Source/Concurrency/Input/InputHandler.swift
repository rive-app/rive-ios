//
//  InputHandler.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// An enum representing input events that can be sent to a state machine.
///
/// Input events are sent to the command queue and processed by the state machine.
/// All operations are fire-and-forget (no listener callbacks).
enum Input {
    case pointerUp(PointerEvent)
    case pointerDown(PointerEvent)
    case pointerMove(PointerEvent)
    case pointerExit(PointerEvent)
}

/// A struct containing pointer event information.
///
/// Contains the position, bounds, fit mode, alignment, and scale factor needed
/// to properly transform pointer coordinates for the state machine.
struct PointerEvent {
    let id: AnyHashable
    let position: CGPoint
    let bounds: CGSize
    let fit: RiveConfigurationFit
    let alignment: RiveConfigurationAlignment
    let scaleFactor: Float
}

/// A class that handles input events and sends them to state machines via the command queue.
///
/// Converts input events into command queue calls. All operations are fire-and-forget
/// (no listener callbacks). All command queue operations must be performed on the main
/// thread (either marked `@MainActor` or dispatched to the main queue).
final class InputHandler {
    private let idPool = IDPool<AnyHashable>(range: 0..<10)
    private let dependencies: Dependencies

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Handles an input event by sending it to the state machine via the command queue.
    ///
    /// Resolves a stable pointer ID from the pool for each event. The ID is upserted
    /// (added if new, reused if existing). For exit events, the ID is additionally
    /// released back to the pool after sending.
    /// Returns `true` if a valid pointer ID was available, `false` otherwise.
    @MainActor
    @discardableResult
    func handle(_ input: Input, in stateMachine: StateMachine) -> Bool {
        switch input {
        case .pointerUp(let event):
            guard let id = idPool.add(event.id) else {
                RiveLog.warning(tag: .view, "[RiveUIView] Dropping pointer up event: no available pointer IDs")
                return false
            }
            RiveLog.trace(tag: .view, "[RiveUIView] Handling pointer up event")
            send(dependencies.commandQueue.pointerUp, id: id, with: event, in: stateMachine)
            idPool.remove(event.id)
        case .pointerDown(let event):
            guard let id = idPool.add(event.id) else {
                RiveLog.warning(tag: .view, "[RiveUIView] Dropping pointer down event: no available pointer IDs")
                return false
            }
            RiveLog.trace(tag: .view, "[RiveUIView] Handling pointer down event")
            send(dependencies.commandQueue.pointerDown, id: id, with: event, in: stateMachine)
        case .pointerMove(let event):
            guard let id = idPool.add(event.id) else {
                RiveLog.warning(tag: .view, "[RiveUIView] Dropping pointer move event: no available pointer IDs")
                return false
            }
            RiveLog.trace(tag: .view, "[RiveUIView] Handling pointer move event")
            send(dependencies.commandQueue.pointerMove, id: id, with: event, in: stateMachine)
        case .pointerExit(let event):
            guard let id = idPool.add(event.id) else {
                RiveLog.warning(tag: .view, "[RiveUIView] Dropping pointer exit event: no available pointer IDs")
                return false
            }
            RiveLog.trace(tag: .view, "[RiveUIView] Handling pointer exit event")
            send(dependencies.commandQueue.pointerExit, id: id, with: event, in: stateMachine)
            idPool.remove(event.id)
        }
        return true
    }

    /// Sends a pointer event to the command queue with a pre-resolved pointer ID.
    @MainActor
    private func send(_ pointerEvent: (UInt64, Int32, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void, id: Int32, with event: PointerEvent, in stateMachine: StateMachine) {
        let requestID = dependencies.commandQueue.nextRequestID
        pointerEvent(stateMachine.stateMachineHandle, id, event.position, event.bounds, event.fit, event.alignment, event.scaleFactor, requestID)
    }
}

extension InputHandler {
    /// Container for all dependencies required by the input handler.
    struct Dependencies {
        /// The command queue used to send input events to the C++ runtime.
        /// All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}
