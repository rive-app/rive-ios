//
//  AppKitFocusSystem.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if os(macOS) && !RIVE_MAC_CATALYST
import AppKit

/// Coordinates native and explicitly requested entry and exit for Rive's
/// AppKit key view.
///
/// AppKit's first responder owns both keyboard input and native key-view focus.
/// This adapter reports those transitions to ``FocusController``;
/// ``RiveController`` coordinates authored input and navigation fallback.
@MainActor
final class AppKitFocusSystem: FocusSystem {
    weak var delegate: (any FocusSystemDelegate)?

    /// Controls key-view eligibility without changing the host's key-view order.
    var isFocusable = false

    /// Direct native entry does not select a different authored node.
    var defaultEntryDirection: FocusTraversalDirection? { nil }

    private var isInvalidated = false

    /// Defers the native entry callback until an explicit request confirms
    /// that AppKit installed the requested rendering view as first responder.
    private weak var keyboardFocusRequest: NSView?

    /// The view whose native entry this adapter reported. A stale request must
    /// not relinquish ownership already accepted by a replacement adapter.
    private weak var nativeFocusOwner: NSView?

    /// The direction to continue after an unsuccessful entry finishes committing.
    private var pendingEntryContinuation: FocusTraversalDirection?

    /// Requests first-responder ownership and enters authored focus once confirmed.
    /// Existing authored focus is preserved by the delegate's entry handling.
    /// Unlike sequential native entry, an unconsumed explicit request does not
    /// continue through the key-view loop.
    /// - Returns: Whether an eligible request established or retained first-responder ownership.
    func requestKeyboardFocus(in view: AppKitMetalView) -> Bool {
        guard !isInvalidated, isFocusable, keyboardFocusRequest == nil,
              view.acceptsFirstResponder, let window = view.window,
              window.isKeyWindow else { return false }

        keyboardFocusRequest = view
        defer { keyboardFocusRequest = nil }

        let wasFirstResponder = window.firstResponder === view
        let accepted = wasFirstResponder || window.makeFirstResponder(view)
        guard !isInvalidated else {
            // AppKit may commit after invalidation. Undo only this request's
            // acquisition, not entry already accepted by a replacement adapter.
            let currentSystem = view.focusSystem
            let hasCurrentOwner = currentSystem?.keyboardFocusRequest === view
                || currentSystem?.nativeFocusOwner === view
            if !wasFirstResponder, window.firstResponder === view, !hasCurrentOwner {
                window.makeFirstResponder(nil)
            }
            return false
        }
        // AppKit can accept the transition but make the window first responder
        // if the requested view declines it. Confirm the actual owner.
        guard accepted, isFocusable,
              view.window === window, window.isKeyWindow,
              window.firstResponder === view else {
            // Track committed native ownership even if the explicit request
            // failed. The controller applies the current entry eligibility.
            if window.firstResponder === view {
                nativeFocusOwner = view
                delegate?.focusSystem(self, didEnter: defaultEntryDirection)
            }
            return false
        }

        pendingEntryContinuation = nil
        nativeFocusOwner = view
        delegate?.focusSystem(self, didEnter: .next)
        return true
    }

    /// Reports native entry; the controller preserves an existing node or
    /// traverses into Rive using AppKit's key-view selection direction.
    /// An unconsumed sequential entry continues through the native key-view loop.
    func didBecomeFirstResponder(in view: NSView, selectionDirection: NSWindow.SelectionDirection) {
        pendingEntryContinuation = nil
        guard !isInvalidated, isFocusable, keyboardFocusRequest !== view else { return }
        nativeFocusOwner = view
        let direction: FocusTraversalDirection?
        switch selectionDirection {
        case .selectingNext: direction = .next
        case .selectingPrevious: direction = .previous
        default: direction = defaultEntryDirection
        }
        guard delegate?.focusSystem(self, didEnter: direction) == false, let direction else { return }
        pendingEntryContinuation = direction
        // becomeFirstResponder is still inside AppKit's responder transition.
        // Wait until it finishes before initiating another transition.
        DispatchQueue.main.async { [weak self, weak view] in
            guard let self, let view else { return }
            continueEntry(from: view)
        }
    }

    /// Clears Rive focus after the rendering view relinquishes first responder.
    func didResignFirstResponder() {
        nativeFocusOwner = nil
        pendingEntryContinuation = nil
        guard !isInvalidated else { return }
        delegate?.focusSystemDidExit(self)
    }

    /// Permanently detaches the adapter from its controller.
    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        keyboardFocusRequest = nil
        nativeFocusOwner = nil
        pendingEntryContinuation = nil
        delegate = nil
    }

    /// Continues one native traversal pass, stopping at accepted entry or a
    /// repeated candidate. Consuming each pending continuation also makes the
    /// callbacks queued by intervening empty Rive views harmless.
    private func continueEntry(from view: NSView) {
        guard let window = view.window else { return }
        var currentView = view
        var currentSystem = self
        var visited: Set<ObjectIdentifier> = []
        while !currentSystem.isInvalidated, currentSystem.isFocusable,
              window.firstResponder === currentView,
              let direction = currentSystem.pendingEntryContinuation {
            currentSystem.pendingEntryContinuation = nil
            guard visited.insert(ObjectIdentifier(currentView)).inserted else { return }
            let candidate = direction == .next ? currentView.nextValidKeyView : currentView.previousValidKeyView
            guard let candidate, !visited.contains(ObjectIdentifier(candidate)) else { return }

            switch direction {
            case .next: window.selectKeyView(following: currentView)
            case .previous: window.selectKeyView(preceding: currentView)
            }
            guard let nextView = window.firstResponder as? AppKitMetalView,
                  let nextSystem = nextView.focusSystem else { return }
            currentView = nextView
            currentSystem = nextSystem
        }
    }
}

#endif
