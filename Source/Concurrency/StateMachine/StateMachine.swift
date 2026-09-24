//
//  RiveUIStateMachine.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import Combine

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
    let sourceArtboard: Artboard
    private let dependencies: Dependencies

    @MainActor private(set) var mainBinding: ViewModelInstance?
    @MainActor private(set) var globalBindings: [String: ViewModelInstance] = [:]

    @MainActor let bindingsDidChange = PassthroughSubject<Void, Never>()
    
    @MainActor
    init(dependencies: Dependencies, stateMachineHandle: StateMachineHandle, sourceArtboard: Artboard) {
        self.dependencies = dependencies
        self.stateMachineHandle = stateMachineHandle
        self.sourceArtboard = sourceArtboard
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
    /// - Returns: `true` if both state machines reference the same underlying state machine handle.
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
    @available(*, deprecated, message: "bindViewModelInstance(_:) will be removed in a future release. Use bindViewModelInstances(main:globals:) instead.")
    @MainActor
    public func bindViewModelInstance(_ viewModelInstance: ViewModelInstance) {
        applyViewModelInstanceBindings(main: viewModelInstance, globals: [])
    }

    /// Binds main and global view model instances to this state machine.
    ///
    /// Each instance accepted by the runtime replaces the instance currently bound in the same
    /// slot. Main and global instances that are not provided are preserved. If a required slot has
    /// neither a provided nor an existing instance, the runtime creates its authored default when
    /// available.
    ///
    /// All supplied global names are validated against the source file before any bindings are
    /// applied. Use ``File.getGlobalViewModelNames()`` to discover the available global names.
    ///
    /// Retain references to any view model instances you need to read or modify after binding.
    /// Bound instances cannot be retrieved through the state machine. Each supplied instance is
    /// retained until it is replaced in its slot or the state machine is deallocated.
    ///
    /// - Parameters:
    ///   - main: The main view model instance to apply, or `nil` to preserve the current instance
    ///   - globals: The global view model instance bindings to apply
    /// - Throws: ``StateMachineError.duplicateGlobalViewModelInstance(_:)`` if the same global name
    ///   appears more than once in one binding call, ``StateMachineError.invalidGlobalViewModelName(_:)``
    ///   if a name is not a global in the source file, ``StateMachineError.error(_:)`` if metadata
    ///   cannot be read, or ``StateMachineError.cancelled`` if the operation is cancelled
    @MainActor
    public func bindViewModelInstances(
        main: ViewModelInstance? = nil,
        @GlobalViewModelInstanceBindingsBuilder globals: () -> [(String, ViewModelInstance)] = { [] }
    ) async throws {
        let globals = globals()
        try GlobalViewModelInstanceBindingsBuilder.validate(globals)
        if globals.isEmpty == false {
            let names: Set<String>
            do {
                names = Set(try await sourceArtboard.sourceFile.getGlobalViewModelNames())
            } catch FileError.cancelled {
                throw StateMachineError.cancelled
            } catch is CancellationError {
                throw StateMachineError.cancelled
            } catch {
                throw StateMachineError.error(error.localizedDescription)
            }
            for (name, _) in globals {
                guard names.contains(name) else {
                    throw StateMachineError.invalidGlobalViewModelName(name)
                }
            }
        }
        guard Task.isCancelled == false else {
            throw StateMachineError.cancelled
        }
        applyViewModelInstanceBindings(main: main, globals: globals)
    }

    @MainActor
    private func applyViewModelInstanceBindings(
        main: ViewModelInstance?,
        globals: [(String, ViewModelInstance)]
    ) {
        if let main {
            setViewModelInstance(main)
        }
        for (name, viewModelInstance) in globals {
            setGlobalViewModelInstance(named: name, to: viewModelInstance)
        }

        bind()

        if let main {
            mainBinding = main
        }
        for (name, viewModelInstance) in globals {
            globalBindings[name] = viewModelInstance
        }
        bindingsDidChange.send()
    }

    @MainActor
    private func setViewModelInstance(_ viewModelInstance: ViewModelInstance) {
        dependencies.stateMachineService.setViewModelInstance(
            stateMachineHandle,
            to: viewModelInstance.viewModelInstanceHandle
        )
    }

    @MainActor
    private func setGlobalViewModelInstance(
        named name: String,
        to viewModelInstance: ViewModelInstance
    ) {
        dependencies.stateMachineService.setGlobalViewModelInstance(
            stateMachineHandle,
            named: name,
            to: viewModelInstance.viewModelInstanceHandle
        )
    }

    @MainActor
    private func bind() {
        dependencies.stateMachineService.bind(stateMachineHandle)
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
