//
//  KeyboardController.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

/// Receives rendering requests after keyboard input is delivered to Rive.
@MainActor
protocol KeyboardControllerDelegate: AnyObject {
    /// Requests a frame after delivery, even when input remains unconsumed.
    func keyboardControllerDidRequestWake(_ controller: KeyboardController)
}

/// Delivers platform-independent keyboard input to a state machine.
///
/// Native event routing and focus traversal are coordinated by the owner.
@MainActor
final class KeyboardController {
    /// The object that schedules rendering after keyboard input is delivered.
    weak var delegate: (any KeyboardControllerDelegate)?

    /// Whether keyboard input is temporarily disabled with the owning view.
    var isPaused = false

    private let dependencies: Dependencies

    /// Whether the controller has permanently stopped accepting keyboard input.
    private var isInvalidated = false

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Permanently stops keyboard input, including after a subsequent resume.
    func invalidate() {
        isInvalidated = true
    }

    /// Synchronously delivers a key event and returns whether Rive handled it.
    ///
    /// Paused or invalidated controllers return `false` without forwarding input
    /// or requesting a frame.
    func keyInput(
        _ key: StateMachine.Key,
        modifiers: StateMachine.KeyModifiers,
        isPressed: Bool,
        isRepeat: Bool
    ) -> Bool {
        guard !isPaused, !isInvalidated else { return false }

        let handled = dependencies.stateMachine.keyInputSynchronized(
            key, modifiers: modifiers, isPressed: isPressed, isRepeat: isRepeat
        )
        // Consumption controls propagation, not whether a script changed state.
        delegate?.keyboardControllerDidRequestWake(self)
        return handled
    }
}

extension KeyboardController {
    /// Dependencies required to deliver keyboard input to Rive.
    struct Dependencies {
        /// The state machine that receives keyboard events.
        let stateMachine: StateMachine
    }
}
