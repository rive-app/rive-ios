//
//  RiveUIStateMachine.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a Rive state machine, managing animation states and transitions.
///
/// State machines control the flow of animations in an artboard, managing state transitions,
/// inputs, and animation playback. They can be bound to view model instances to enable
/// data-driven animations.
@_spi(RiveExperimental)
public class StateMachine {
    /// The underlying type for the state machine handle identifier.
    ///
    /// Handle to a state machine instance in the C++ runtime. Obtained from the command queue
    /// when a state machine is created via `StateMachineService.createStateMachine`, and used
    /// in all subsequent command queue operations. Automatically cleaned up when this
    /// `StateMachine` instance is deallocated via `StateMachineService.deleteStateMachine`.
    typealias StateMachineHandle = UInt64

    let stateMachineHandle: StateMachineHandle
    private let dependencies: Dependencies

    @MainActor
    convenience init(name: String? = nil, from artboard: Artboard.ArtboardHandle, dependencies: Dependencies) {
        let handle = dependencies.stateMachineService.createStateMachine(name: name, from: artboard)
        self.init(
            dependencies: dependencies,
            stateMachineHandle: handle
        )
    }

    @MainActor
    init(dependencies: Dependencies, stateMachineHandle: StateMachineHandle) {
        self.dependencies = dependencies
        self.stateMachineHandle = stateMachineHandle
    }

    deinit {
        let service = dependencies.stateMachineService
        let handle = stateMachineHandle
        Task { @MainActor in
            service.deleteStateMachine(handle)
        }
    }

    /// Compares two StateMachine instances for equality.
    ///
    /// Two state machine instances are considered equal if they reference the same underlying
    /// state machine handle. This means they represent the same state machine in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side state machine instance.
    ///   - rhs: The right-hand side state machine instance.
    /// - Returns: `true` if both artboards reference the same underlying artboard handle.
    public static func ==(lhs: StateMachine, rhs: StateMachine) -> Bool {
        return lhs.stateMachineHandle == rhs.stateMachineHandle
    }

    /// Advances the state machine's animation timeline by the specified time interval.
    ///
    /// This method updates the state machine's internal clock and processes any state transitions,
    /// input changes, or animation updates that occur during the elapsed time. It should be called
    /// regularly (typically each frame) to keep the animation playing.
    ///
    /// - Parameter time: The time interval in seconds to advance the state machine
    @MainActor
    public func advance(by time: TimeInterval) {
        dependencies.stateMachineService.advanceStateMachine(stateMachineHandle, by: time)
    }

    /// Binds a view model instance to this state machine.
    ///
    /// Binding a view model instance allows the state machine to access and modify view model
    /// properties during state transitions and animations, enabling data-driven animations.
    ///
    /// - Parameter viewModelInstance: The view model instance to bind to this state machine
    @MainActor
    public func bindViewModelInstance(_ viewModelInstance: ViewModelInstance) {
        dependencies.stateMachineService.bindViewModelInstance(stateMachineHandle, to: viewModelInstance.viewModelInstanceHandle)
    }
}

extension StateMachine {
    /// Container for all dependencies required by a StateMachine instance.
    struct Dependencies {
        /// Provides state machine-level services via command queue interactions.
        /// All operations are fire-and-forget (no listener callbacks).
        let stateMachineService: StateMachineService
    }
}
