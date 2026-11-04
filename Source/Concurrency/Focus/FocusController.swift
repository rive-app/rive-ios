//
//  FocusController.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

/// Receives wake requests from a ``FocusController``.
@MainActor
protocol FocusControllerDelegate: AnyObject {
    /// Requests a frame after a change to Rive focus.
    func focusControllerDidRequestWake(_ controller: FocusController)
}

/// Coordinates authored Rive focus nodes with a platform focus system.
@MainActor
final class FocusController {
    /// The object that schedules rendering after focus traversal attempts.
    weak var delegate: (any FocusControllerDelegate)?

    #if TESTING
    /// Observes when a focus state has been applied by the controller.
    var onFocusStateApplied: ((StateMachine.FocusState) -> Void)?
    #endif

    /// Whether focus handling is temporarily disabled with the owning view.
    ///
    /// Pausing ignores input and preserves an existing native focus session.
    /// Once native focus leaves, the view is excluded from traversal until resume.
    var isPaused = false {
        didSet {
            guard isPaused != oldValue else { return }
            if isPaused {
                availabilityTask?.cancel()
                availabilityTask = nil
                needsAvailabilityRefresh = false
                cancelFocusStateRequest()
            }
            updateFocusability()
        }
    }

    private let dependencies: Dependencies

    /// Queries whether the state machine has authored focus nodes.
    private var availabilityTask: Task<Void, Never>?

    /// Records advances that need a fresh query after the current one finishes.
    private var needsAvailabilityRefresh = false

    /// Queries a focus-state snapshot without restarting for each advance.
    private var focusStateTask: Task<Void, Never>?

    /// Records advances that need a fresh snapshot after the current query finishes.
    private var needsFocusStateRefresh = false

    /// The latest focus state confirmed by the runtime.
    private(set) var focusState: StateMachine.FocusState?

    /// Whether the latest snapshot or synchronous traversal confirmed a
    /// focused Rive node.
    private var hasFocusedRiveNode = false

    /// Whether native focus is currently inside the Rive view.
    private var hasNativeFocus: Bool

    /// Defers entry into replacement content until its first focus snapshot,
    /// when the platform requires a starting node for retained native focus.
    private var pendingEntryDirection: FocusTraversalDirection?

    /// Whether the state machine contains authored focus nodes.
    private var hasFocusNodes = false

    /// Indicates whether the controller has permanently stopped handling focus.
    private var isInvalidated = false

    /// Preserves native ownership when attaching to an already-focused view.
    /// Any platform-required entry waits for the new graphic's focus snapshot.
    init(dependencies: Dependencies, hasNativeFocus: Bool = false) {
        self.dependencies = dependencies
        self.hasNativeFocus = hasNativeFocus
        pendingEntryDirection = hasNativeFocus ? dependencies.focusSystem.defaultEntryDirection : nil
        setFocusable(false)
        dependencies.focusSystem.delegate = self
    }

    deinit {
        availabilityTask?.cancel()
        focusStateTask?.cancel()
    }

    /// Refreshes the focus-node availability and focus state produced by the
    /// latest state machine advance.
    ///
    /// At most one request of each kind is active at a time; advances during a
    /// pending request are coalesced into one follow-up query. Focus snapshots
    /// are cancelled when input or lifecycle changes make their answers obsolete,
    /// not merely because another advance occurred.
    /// Focus state is queried only while authored nodes are available.
    func didAdvance() {
        guard !isPaused, !isInvalidated else { return }

        refreshAvailability()
        refreshFocusState()
    }

    /// Discards a pending snapshot that predates keyboard-driven focus changes.
    func prepareForKeyboardInput() {
        cancelFocusStateRequest()
    }

    /// Attempts focus navigation after authored keyboard handling declines a key.
    ///
    /// Tab and Shift-Tab traverse sequentially. Unmodified arrows traverse
    /// spatially, except on tvOS where native focus proposals handle movement.
    /// Releases and other key combinations remain available to the platform.
    /// - Returns: Whether Rive consumed the navigation request.
    func handleNavigationKey(
        _ key: StateMachine.Key,
        modifiers: StateMachine.KeyModifiers,
        isPressed: Bool
    ) -> Bool {
        guard isPressed else { return false }
        if key == .tab, modifiers.subtracting(.shift).isEmpty {
            return traverse(modifiers.contains(.shift) ? .previous : .next)
        }
        guard modifiers.isEmpty else { return false }
        #if os(tvOS)
        // UIKit supplies remote and unhandled keyboard movement as focus
        // headings; attempting it here as well would traverse twice.
        return false
        #else
        let direction: StateMachine.FocusDirection
        switch key {
        case .left: direction = .left
        case .right: direction = .right
        case .up: direction = .up
        case .down: direction = .down
        default: return false
        }
        return focusInDirection(direction)
        #endif
    }

    /// Performs sequential traversal for native entry or an unhandled Tab press.
    /// - Returns: Whether Rive consumed navigation by moving or retaining focus.
    func traverse(_ direction: FocusTraversalDirection) -> Bool {
        guard !isPaused, !isInvalidated, dependencies.focusSystem.isFocusable else {
            return false
        }
        cancelFocusStateRequest()
        let result: StateMachine.FocusTraversalResult
        switch direction {
        case .next:
            result = dependencies.stateMachine.focusNextWithResultSynchronized()
        case .previous:
            result = dependencies.stateMachine.focusPreviousWithResultSynchronized()
        }
        hasFocusedRiveNode = result.focusState.hasFocus
        focusState = result.focusState
        delegate?.focusControllerDidRequestWake(self)
        return result.consumed
    }

    /// Attempts spatial traversal without falling back to sequential movement.
    /// Native focus loss remains responsible for clearing Rive focus.
    func focusInDirection(_ direction: StateMachine.FocusDirection) -> Bool {
        guard !isPaused, !isInvalidated, dependencies.focusSystem.isFocusable else { return false }
        cancelFocusStateRequest()
        let moved = dependencies.stateMachine.focusInDirectionSynchronized(direction)
        if moved {
            hasFocusedRiveNode = true
        }
        // Core may discard a hidden focus target even when no directional move succeeds.
        delegate?.focusControllerDidRequestWake(self)
        return moved
    }

    private func refreshAvailability() {
        guard !isPaused, !isInvalidated else { return }
        guard availabilityTask == nil else {
            needsAvailabilityRefresh = true
            return
        }
        needsAvailabilityRefresh = false
        let stateMachine = dependencies.stateMachine
        availabilityTask = Task { @MainActor [weak self] in
            // Pause can replace a cancelled request before its cleanup runs.
            defer {
                if !Task.isCancelled, let self {
                    availabilityTask = nil
                    if needsAvailabilityRefresh { refreshAvailability() }
                }
            }
            do {
                let hasFocusNodes = try await stateMachine.hasFocusNodes()
                guard let self, !Task.isCancelled, !isPaused, !isInvalidated else { return }
                updateAvailability(hasFocusNodes)
            } catch {
                guard let self, !Task.isCancelled, !isPaused, !isInvalidated else { return }
                updateAvailability(false)
                RiveLog.error(tag: .view, error: error, "[RiveUIView] Failed to query focus nodes")
            }
        }
    }

    /// Discards snapshots when nodes disappear and requests a fresh one when
    /// they appear, even if the state machine has already stopped advancing.
    private func updateAvailability(_ hasFocusNodes: Bool) {
        let previouslyHadFocusNodes = self.hasFocusNodes
        self.hasFocusNodes = hasFocusNodes
        if !hasFocusNodes {
            cancelFocusStateRequest()
            focusState = nil
            hasFocusedRiveNode = false
        }
        updateFocusability()
        if hasFocusNodes, !previouslyHadFocusNodes {
            refreshFocusState()
        }
    }

    private func refreshFocusState() {
        guard !isPaused, !isInvalidated, hasFocusNodes else { return }
        guard focusStateTask == nil else {
            needsFocusStateRefresh = true
            return
        }
        needsFocusStateRefresh = false
        let stateMachine = dependencies.stateMachine
        focusStateTask = Task { @MainActor [weak self] in
            // Cancelled requests must not clear or refresh a replacement task.
            defer {
                if !Task.isCancelled, let self {
                    focusStateTask = nil
                    if needsFocusStateRefresh { refreshFocusState() }
                }
            }
            do {
                let focusState = try await stateMachine.focusState()
                guard let self, !Task.isCancelled, !isPaused, !isInvalidated else { return }
                applyFocusState(focusState)
            } catch {
                guard let self, !Task.isCancelled, !isPaused, !isInvalidated else { return }
                focusState = nil
                updateFocusability()
                RiveLog.error(tag: .view, error: error, "[RiveUIView] Failed to query focus state")
            }
        }
    }

    /// Cancels the awaiting task so its snapshot cannot update the controller.
    /// Commands already submitted to the queue may still finish executing.
    private func cancelFocusStateRequest() {
        focusStateTask?.cancel()
        focusStateTask = nil
        needsFocusStateRefresh = false
    }

    /// Permanently stops focus handling and detaches the focus system.
    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        availabilityTask?.cancel()
        availabilityTask = nil
        needsAvailabilityRefresh = false
        cancelFocusStateRequest()
        hasFocusNodes = false
        focusState = nil
        hasFocusedRiveNode = false
        hasNativeFocus = false
        pendingEntryDirection = nil
        setFocusable(false)
        dependencies.stateMachine.clearFocus()
        delegate = nil
        dependencies.focusSystem.delegate = nil
        dependencies.focusSystem.invalidate()
    }

    private func applyFocusState(_ focusState: StateMachine.FocusState) {
        hasFocusedRiveNode = focusState.hasFocus
        self.focusState = focusState

        updateFocusability()

        // Initialize retained native focus once, without refocusing after a
        // later authored blur or replacing a node already chosen by the graphic.
        if let direction = pendingEntryDirection {
            pendingEntryDirection = nil
            if hasNativeFocus, !hasFocusedRiveNode {
                _ = traverse(direction)
            }
        }

        #if TESTING
        onFocusStateApplied?(focusState)
        #endif
    }

    private func updateFocusability() {
        setFocusable(!isInvalidated && (!isPaused || hasNativeFocus)
            && hasFocusNodes && focusState != nil)
    }

    private func setFocusable(_ isFocusable: Bool) {
        guard dependencies.focusSystem.isFocusable != isFocusable else { return }
        dependencies.focusSystem.isFocusable = isFocusable
    }
}

extension FocusController: FocusSystemDelegate {
    #if os(tvOS)
    func focusSystem(_ focusSystem: any FocusSystem, moveIn direction: StateMachine.FocusDirection) -> Bool {
        guard focusSystem === dependencies.focusSystem else { return false }
        return focusInDirection(direction)
    }
    #endif

    /// Preserves a known node on native entry, otherwise enters the Rive tree
    /// in the platform's sequential direction when one is available.
    /// - Returns: Whether to retain native entry rather than continue traversal.
    @discardableResult
    func focusSystem(
        _ focusSystem: any FocusSystem,
        didEnter direction: FocusTraversalDirection?
    ) -> Bool {
        guard focusSystem === dependencies.focusSystem, !isInvalidated else { return true }
        pendingEntryDirection = nil
        hasNativeFocus = true
        guard !isPaused, !hasFocusedRiveNode, focusSystem.isFocusable, let direction else { return true }
        return traverse(direction)
    }

    /// Clears authored focus on native exit, including while paused.
    func focusSystemDidExit(_ focusSystem: any FocusSystem) {
        guard focusSystem === dependencies.focusSystem else { return }
        guard !isInvalidated else { return }
        cancelFocusStateRequest()
        pendingEntryDirection = nil
        hasNativeFocus = false
        hasFocusedRiveNode = false
        updateFocusability()
        dependencies.stateMachine.clearFocus()
        delegate?.focusControllerDidRequestWake(self)
    }
}

extension FocusController {
    /// Dependencies required to coordinate platform and Rive focus state.
    struct Dependencies {
        /// The state machine whose authored focus nodes are controlled.
        let stateMachine: StateMachine
        /// The platform adapter that supplies focus events.
        let focusSystem: any FocusSystem
    }
}
