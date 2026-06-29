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
public final class StateMachine: Equatable {
    /// The underlying type for the state machine handle identifier.
    ///
    /// Handle to a state machine instance in the C++ runtime. Obtained from the command queue
    /// when a state machine is created via `ArtboardService.instantiateStateMachine`, and used
    /// in all subsequent command queue operations. Automatically cleaned up when this
    /// `StateMachine` instance is deallocated via `StateMachineService.deleteStateMachine`.
    typealias StateMachineHandle = UInt64

    let stateMachineHandle: StateMachineHandle
    private let dependencies: Dependencies
    
    @MainActor
    init(dependencies: Dependencies, stateMachineHandle: StateMachineHandle) {
        self.dependencies = dependencies
        self.stateMachineHandle = stateMachineHandle
    }

    deinit {
        let service = dependencies.stateMachineService
        let handle = stateMachineHandle
        RiveLog.debug(tag: .stateMachine, "[StateMachine (\(handle))] Deinitializing state machine; scheduling cleanup")
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteStateMachine(handle) else { return }
            service.deleteStateMachineListener(deletedHandle)
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

    /// Stream of state machine settled events.
    ///
    /// Emits `Void` each time the runtime reports this state machine has settled.
    @MainActor
    public func settledStream() -> AsyncStream<Void> {
        return dependencies.stateMachineService.settledStream(for: stateMachineHandle)
    }

    @MainActor
    var hasActiveListeners: Bool {
        return dependencies.stateMachineService.hasActiveListeners()
    }

    /// Enables the accessibility semantics subsystem for this state machine.
    ///
    /// Must be called before semantics diffs are delivered. Safe to call multiple times.
    @MainActor
    public func enableSemantics() {
        dependencies.stateMachineService.enableSemantics(for: stateMachineHandle)
    }

    /// Stream of incremental semantics diffs.
    ///
    /// After calling ``enableSemantics()``, this stream emits a ``SemanticsDiff``
    /// each time the accessibility tree changes. Multiple subscribers are supported.
    @MainActor
    public func semanticsDiffStream() -> AsyncStream<SemanticsDiff> {
        return dependencies.stateMachineService.semanticsDiffStream(for: stateMachineHandle)
    }

    /// Fires a semantic action on a semantic node.
    ///
    /// - Parameters:
    ///   - nodeID: The identifier of the semantic node to act on.
    ///   - actionType: The type of action to fire.
    @MainActor
    public func fireSemanticAction(nodeID: UInt32, actionType: SemanticActionType) {
        dependencies.stateMachineService.fireSemanticAction(on: stateMachineHandle, nodeID: nodeID, actionType: actionType)
    }

    /// Requests focus on a specific semantic node.
    ///
    /// - Parameter nodeID: The identifier of the semantic node to focus.
    @MainActor
    public func requestSemanticFocus(nodeID: UInt32) {
        dependencies.stateMachineService.requestSemanticFocus(on: stateMachineHandle, nodeID: nodeID)
    }

    /// Clears semantic focus from all nodes.
    @MainActor
    public func clearSemanticFocus() {
        dependencies.stateMachineService.clearSemanticFocus(on: stateMachineHandle)
    }

    /// Drains the semantic diff for this state machine.
    ///
    /// Must be called after every ``advance(by:)`` when semantics are enabled.
    /// The C++ runtime transforms artboard-space bounds into view-space using
    /// the provided fit, alignment, scale, and view bounds parameters.
    ///
    /// - Parameters:
    ///   - fit: The current content fit mode.
    ///   - alignment: The current content alignment.
    ///   - scaleFactor: The display scale factor (points to pixels).
    ///   - viewBounds: The view size in pixels.
    @MainActor
    public func drainSemanticsDiff(
        fit: RiveConfigurationFit,
        alignment: RiveConfigurationAlignment,
        scaleFactor: Float,
        viewBounds: CGSize
    ) {
        dependencies.stateMachineService.drainSemanticsDiff(
            for: stateMachineHandle,
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            viewBounds: viewBounds
        )
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
        /// Implements `StateMachineListener` to receive callbacks from the command server.
        let stateMachineService: StateMachineService
    }
}
