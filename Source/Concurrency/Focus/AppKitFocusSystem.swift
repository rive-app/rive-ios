//
//  AppKitFocusSystem.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if os(macOS) && !RIVE_MAC_CATALYST
import AppKit

/// Coordinates native entry and exit for Rive's AppKit key view.
@MainActor
final class AppKitFocusSystem: FocusSystem {
    weak var delegate: (any FocusSystemDelegate)?

    /// Controls key-view eligibility without changing the host's key-view order.
    var isFocusable = false

    /// Direct native entry does not select a different authored node.
    var defaultEntryDirection: FocusTraversalDirection? { nil }

    private var isInvalidated = false

    /// The direction to continue after an unsuccessful entry finishes committing.
    private var pendingEntryContinuation: FocusTraversalDirection?

    /// Reports native entry; the controller preserves an existing node or
    /// traverses into Rive using AppKit's key-view selection direction.
    /// An unconsumed sequential entry continues through the native key-view loop.
    func didBecomeFirstResponder(in view: NSView, selectionDirection: NSWindow.SelectionDirection) {
        pendingEntryContinuation = nil
        guard !isInvalidated, isFocusable else { return }
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
        pendingEntryContinuation = nil
        guard !isInvalidated else { return }
        delegate?.focusSystemDidExit(self)
    }

    /// Permanently detaches the adapter from its controller.
    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
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
