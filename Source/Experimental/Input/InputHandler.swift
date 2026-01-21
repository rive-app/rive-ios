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
class InputHandler {
    private let dependencies: Dependencies

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Handles an input event by sending it to the state machine via the command queue.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    func handle(_ input: Input, in stateMachine: StateMachine) {
        switch input {
        case .pointerUp(let event):
            send(dependencies.commandQueue.pointerUp, with: event, in: stateMachine)
        case .pointerDown(let event):
            send(dependencies.commandQueue.pointerDown, with: event, in: stateMachine)
        case .pointerMove(let event):
            send(dependencies.commandQueue.pointerMove, with: event, in: stateMachine)
        case .pointerExit(let event):
            send(dependencies.commandQueue.pointerExit, with: event, in: stateMachine)
        }
    }

    /// Sends a pointer event to the command queue.
    ///
    /// Creates a request ID and calls the appropriate command queue function with the event data.
    private func send(_ pointerEvent: (UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void, with event: PointerEvent, in stateMachine: StateMachine) -> Void {
        let requestID = dependencies.commandQueue.nextRequestID
        pointerEvent(stateMachine.stateMachineHandle, event.position, event.bounds, event.fit, event.alignment, event.scaleFactor, requestID)
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
