//
//  RiveUIStateMachineService.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages state machine operations and coordinates with the command queue.
///
/// Handles state machine creation, advancement, deletion, and view model binding. All operations
/// are fire-and-forget (no listener callbacks). All command queue operations must be performed
/// on the main thread (either marked `@MainActor` or dispatched to the main queue).
class StateMachineService: NSObject {
    private let dependencies: Dependencies

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
    }

    /// Creates a state machine from an artboard.
    ///
    /// Delegates to the command queue. Returns immediately with the state machine handle.
    /// No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - name: The name of the state machine to create. If `nil`, the default state machine is created.
    ///   - artboard: The handle of the artboard containing the state machine.
    /// - Returns: A handle that uniquely identifies the created state machine.
    @MainActor
    func createStateMachine(name: String? = nil, from artboard: Artboard.ArtboardHandle) -> StateMachine.StateMachineHandle {
        let requestID = dependencies.commandQueue.nextRequestID
        if let name = name {
            return dependencies.commandQueue.createStateMachineNamed(name, fromArtboard: artboard, requestID: requestID)
        } else {
            return dependencies.commandQueue.createDefaultStateMachine(fromArtboard: artboard, requestID: requestID)
        }
    }

    /// Advances a state machine by the specified time interval.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - stateMachine: The handle of the state machine to advance.
    ///   - time: The time interval to advance the state machine by.
    @MainActor
    func advanceStateMachine(_ stateMachine: StateMachine.StateMachineHandle, by time: TimeInterval) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.advanceStateMachine(stateMachine, by: time, requestID: requestID)
    }

    /// Deletes a state machine via the command queue.
    ///
    /// After deletion, the state machine handle becomes invalid. This operation is irreversible.
    /// No listener callback is invoked for this operation.
    @MainActor
    func deleteStateMachine(_ stateMachine: StateMachine.StateMachineHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.deleteStateMachine(stateMachine, requestID: requestID)
    }

    /// Binds a view model instance to a state machine.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    ///
    /// - Parameters:
    ///   - stateMachine: The handle of the state machine to bind to.
    ///   - viewModelInstance: The handle of the view model instance to bind.
    @MainActor
    func bindViewModelInstance(_ stateMachine: StateMachine.StateMachineHandle, to viewModelInstance: ViewModelInstance.ViewModelInstanceHandle) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.bindViewModelInstance(stateMachine, toViewModelInstance: viewModelInstance, requestID: requestID)
    }
}

extension StateMachineService {
    /// Container for all dependencies required by the state machine service.
    struct Dependencies {
        /// The command queue used to send state machine-related commands to the C++ runtime.
        /// All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}

