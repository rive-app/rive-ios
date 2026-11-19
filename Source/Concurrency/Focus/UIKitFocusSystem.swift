//
//  UIKitFocusSystem.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

/// Coordinates native entry, exit, and keyboard-responder ownership for Rive's
/// UIKit focus item.
///
/// Native focus means UIKit's focus engine has selected the rendering view for
/// navigation. Keyboard ownership means the view confirmed first-responder
/// acquisition, which can succeed before native focus is active.
///
/// This adapter reports ownership changes to ``FocusController``; it does not
/// interpret keys or deliver them to the state machine. ``RiveController``
/// coordinates that delivery with ``KeyboardController`` and navigation fallback.
@MainActor
final class UIKitFocusSystem: FocusSystem {
    /// The controller that handles translated UIKit focus events.
    weak var delegate: (any FocusSystemDelegate)?

    /// Whether UIKit should include the Rive rendering view in focus traversal.
    var isFocusable = false

    /// tvOS also initializes replacement content while native focus is retained.
    var defaultEntryDirection: FocusTraversalDirection? {
        #if os(tvOS)
        return .next
        #else
        return nil
        #endif
    }

    /// The ancestor that defines the native Rive focus environment. Clearing it
    /// on invalidation permanently disconnects the adapter.
    private weak var focusEnvironment: UIView?

    /// The rendering view targeted by the current explicit request. Permission
    /// to enter without a heading lasts only for this request, not later updates.
    private weak var keyboardFocusRequest: UIView?

    /// The rendering view with confirmed first-responder keyboard ownership.
    /// Native focus may remain inactive until the user starts keyboard navigation.
    private weak var keyboardFocusOwner: UIKitMetalView?

    /// A standard acquisition awaiting the end of UIKit's native focus transition.
    private weak var pendingKeyboardFocusOwner: UIKitMetalView?

    #if os(tvOS)
    /// Reuses a traversal decision while UIKit synchronously retries native
    /// destinations for the same directional movement.
    private var navigationDecision: (direction: StateMachine.FocusDirection, handled: Bool)?
    #endif

    init(dependencies: Dependencies) {
        focusEnvironment = dependencies.focusEnvironment
    }

    /// Requests first-responder ownership and enters authored focus once confirmed.
    /// Existing authored focus is preserved by the delegate's entry handling.
    ///
    /// Ownership does not activate native navigation focus, and focus groups or
    /// identifiers do not grant it. Unhandled navigation stays with UIKit until
    /// native focus is active, so the first unhandled Tab may activate native
    /// focus without traversing Rive. Requests are not deferred until readiness.
    /// - Returns: Whether an eligible request established or retained first-responder ownership.
    func requestKeyboardFocus(in view: UIKitMetalView) -> Bool {
        guard isFocusable, keyboardFocusRequest == nil,
              let focusEnvironment, view.isDescendant(of: focusEnvironment),
              view.window?.isKeyWindow == true else { return false }

        keyboardFocusRequest = view
        defer { keyboardFocusRequest = nil }

        let wasFirstResponder = view.isFirstResponder
        let accepted = wasFirstResponder || view.becomeFirstResponder()
        guard self.focusEnvironment != nil else {
            if !wasFirstResponder { releaseAbandonedKeyboardFocus(in: view) }
            return false
        }
        guard accepted, isFocusable, view.window?.isKeyWindow == true,
              view.isFirstResponder else {
            // UIKit may have committed native focus even though the explicit
            // request failed. Preserve that entry without claiming keyboard ownership.
            if view.isFocused {
                delegate?.focusSystem(self, didEnter: defaultEntryDirection)
            } else if !wasFirstResponder {
                // This failed request no longer claims the responder it acquired.
                keyboardFocusRequest = nil
                releaseAbandonedKeyboardFocus(in: view)
            }
            return false
        }
        keyboardFocusOwner = view
        delegate?.focusSystem(self, didEnter: .next)
        return true
    }

    /// Reports first-responder acquisition, including standard SwiftUI focus.
    /// Standard entry waits for UIKit's transition to finish so a native heading
    /// can take precedence. Explicit requests report their own synchronous entry.
    func didBecomeFirstResponder(in view: UIKitMetalView, wasFirstResponder: Bool) {
        guard validateKeyboardFocus(in: view, wasFirstResponder: wasFirstResponder) else { return }
        pendingKeyboardFocusOwner = view
        // Keep the adapter alive for this transition so replacement can still
        // release an acquisition that no longer belongs to a current session.
        DispatchQueue.main.async { [weak view] in
            guard let view else { return }
            self.confirmKeyboardFocus(in: view, wasFirstResponder: wasFirstResponder)
        }
    }

    /// Confirms direct keyboard ownership only when native navigation did not
    /// already consume the pending entry with its own traversal direction.
    private func confirmKeyboardFocus(in view: UIKitMetalView, wasFirstResponder: Bool) {
        guard pendingKeyboardFocusOwner === view else { return }
        pendingKeyboardFocusOwner = nil
        guard validateKeyboardFocus(in: view, wasFirstResponder: wasFirstResponder) else { return }
        keyboardFocusOwner = view
        // Standard acquisition has no traversal direction, so it selects no node
        // until sequential navigation, matching AppKit's direct selection.
        delegate?.focusSystem(self, didEnter: nil)
    }

    /// Validates standard entry without duplicating native or explicit entry.
    /// Releases a new acquisition if it is no longer eligible or current.
    private func validateKeyboardFocus(in view: UIKitMetalView, wasFirstResponder: Bool) -> Bool {
        guard let focusEnvironment, view.focusSystem === self else {
            if !wasFirstResponder { releaseAbandonedKeyboardFocus(in: view) }
            return false
        }
        guard !view.isFocused, keyboardFocusRequest !== view, keyboardFocusOwner !== view,
              pendingKeyboardFocusOwner !== view else { return false }
        guard isFocusable, view.isDescendant(of: focusEnvironment),
              view.window?.isKeyWindow == true, view.isFirstResponder else {
            if !wasFirstResponder { releaseAbandonedKeyboardFocus(in: view) }
            return false
        }
        return true
    }

    /// Whether confirmed first-responder ownership still supplies keyboard input
    /// independently of UIKit's focus engine.
    func ownsKeyboardInput(in view: UIView) -> Bool {
        keyboardFocusOwner === view && view.isFirstResponder
    }

    /// Ends keyboard ownership when UIKit transfers the responder.
    /// Native focus, if still present, reports its exit through didUpdateFocus.
    func didResignKeyboardFocus(in view: UIView) {
        if pendingKeyboardFocusOwner === view { pendingKeyboardFocusOwner = nil }
        guard keyboardFocusOwner === view else { return }
        keyboardFocusOwner = nil
        if !view.isFocused { delegate?.focusSystemDidExit(self) }
    }

    /// Determines whether UIKit should accept its proposed focus update.
    ///
    /// Keyboard input owns internal traversal on iOS. On tvOS, spatial focus
    /// proposals give Rive an opportunity to consume remote navigation.
    ///
    /// - Returns: `false` for passive transfer from another item or consumed
    ///   tvOS navigation.
    func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return shouldUpdateFocus(
            from: context.previouslyFocusedItem,
            to: context.nextFocusedItem,
            heading: context.focusHeading
        )
    }

    /// Observes a committed UIKit focus update to detect entry into or exit
    /// from the Rive focus environment.
    ///
    /// If sequential entry cannot focus a Rive node, native focus remains on
    /// the view until another navigation input. UIKit has no public API to
    /// continue the original next/previous movement after entry commits.
    func didUpdateFocus(in context: UIFocusUpdateContext) {
        didUpdateFocus(
            from: context.previouslyFocusedItem,
            to: context.nextFocusedItem,
            heading: context.focusHeading
        )
    }

    /// Permanently disables the adapter and clears its delegate.
    func invalidate() {
        focusEnvironment = nil
        keyboardFocusRequest = nil
        delegate = nil
        let owner = keyboardFocusOwner ?? pendingKeyboardFocusOwner
        keyboardFocusOwner = nil
        pendingKeyboardFocusOwner = nil
        if let owner { releaseAbandonedKeyboardFocus(in: owner) }
    }

    func shouldUpdateFocus(
        from previouslyFocusedItem: (any UIFocusItem)?,
        to nextFocusedItem: (any UIFocusItem)?,
        heading: UIFocusHeading
    ) -> Bool {
        guard isFocusable, let focusEnvironment else { return true }
        let wasInsideRive = isFocusItem(previouslyFocusedItem, within: focusEnvironment)
        let isInsideRive = isFocusItem(nextFocusedItem, within: focusEnvironment)
        guard wasInsideRive != isInsideRive else { return true }
        #if os(tvOS)
        // Let the controller attempt spatial movement. Native exit clears
        // focus only after it commits.
        if nextFocusedItem != nil,
           wasInsideRive,
           let direction = spatialDirection(for: heading) {
            return !handleNavigation(direction)
        }
        #endif
        // Allow initial or restored focus when no item owns it, but do not
        // passively take focus from another item as availability changes.
        return previouslyFocusedItem == nil || wasInsideRive || !heading.isEmpty
            || (keyboardFocusRequest != nil && nextFocusedItem === keyboardFocusRequest)
    }

    func didUpdateFocus(
        from previouslyFocusedItem: (any UIFocusItem)?,
        to nextFocusedItem: (any UIFocusItem)?,
        heading: UIFocusHeading
    ) {
        guard let focusEnvironment else { return }
        if let pendingKeyboardFocusOwner, nextFocusedItem === pendingKeyboardFocusOwner {
            self.pendingKeyboardFocusOwner = nil
        }
        let wasInsideRive = isFocusItem(previouslyFocusedItem, within: focusEnvironment)
        let isInsideRive = isFocusItem(nextFocusedItem, within: focusEnvironment)
        guard wasInsideRive != isInsideRive else { return }

        if wasInsideRive {
            keyboardFocusOwner = nil
            pendingKeyboardFocusOwner = nil
            delegate?.focusSystemDidExit(self)
            return
        }

        guard isFocusable else { return }
        if isKeyboardEntry(to: nextFocusedItem) { return }
        delegate?.focusSystem(self, didEnter: traversalDirection(for: heading))
    }

    /// Whether an explicit request or confirmed owner already accounts for entry.
    /// Pending standard acquisitions leave native headings free to choose direction.
    private func isKeyboardEntry(to item: (any UIFocusItem)?) -> Bool {
        guard let item else { return false }
        return keyboardFocusRequest === item || keyboardFocusOwner === item
    }

    /// Releases ownership no longer claimed by this adapter, without resigning
    /// ownership already accepted or requested by a replacement adapter.
    private func releaseAbandonedKeyboardFocus(in view: UIKitMetalView) {
        let currentSystem = view.focusSystem
        let hasCurrentOwner = currentSystem?.isKeyboardEntry(to: view) == true
            || currentSystem?.pendingKeyboardFocusOwner === view
        if view.isFirstResponder, !hasCurrentOwner {
            view.resignFirstResponder()
        }
    }

    /// Maps sequential and native wrap headings to the same Rive directions.
    private func traversalDirection(for heading: UIFocusHeading) -> FocusTraversalDirection? {
        #if os(tvOS)
        // Enter from the leading or trailing end of the authored traversal
        // order. Preserve any existing focused node in the controller.
        if heading.contains(.down) || heading.contains(.right) { return .next }
        if heading.contains(.up) || heading.contains(.left) { return .previous }
        #endif
        if heading.isEmpty { return defaultEntryDirection }
        if heading.contains(.next) || heading.contains(.first) {
            return .next
        }
        if heading.contains(.previous) || heading.contains(.last) {
            return .previous
        }
        return nil
    }

    private func isFocusItem(
        _ item: (any UIFocusItem)?,
        within environment: any UIFocusEnvironment
    ) -> Bool {
        var focusEnvironment: (any UIFocusEnvironment)? = item
        while let currentEnvironment = focusEnvironment {
            if currentEnvironment === environment {
                return true
            }
            focusEnvironment = currentEnvironment.parentFocusEnvironment
        }
        return false
    }

    #if os(tvOS)
    /// Handles remote movement with no native destination, such as horizontal
    /// navigation when the only sibling controls are above and below Rive.
    func didFailToMoveFocus(in context: UIFocusUpdateContext) {
        guard isFocusable, let focusEnvironment,
              context.nextFocusedItem == nil,
              isFocusItem(context.previouslyFocusedItem, within: focusEnvironment),
              let direction = spatialDirection(for: context.focusHeading) else { return }
        // A rejected proposal still has a destination and was already handled
        // by shouldUpdateFocus. Only destination-less movement reaches here.
        _ = handleNavigation(direction)
    }

    /// Performs one traversal for a burst of UIKit proposals. Clearing on the
    /// next main-queue turn lets subsequent input navigate again without a
    /// time-based debounce, while sharing the decision with failure callbacks.
    private func handleNavigation(_ direction: StateMachine.FocusDirection) -> Bool {
        if let navigationDecision, navigationDecision.direction == direction {
            return navigationDecision.handled
        }
        if navigationDecision == nil {
            DispatchQueue.main.async { [weak self] in
                self?.navigationDecision = nil
            }
        }
        let handled = delegate?.focusSystem(self, moveIn: direction) ?? false
        navigationDecision = (direction, handled)
        return handled
    }

    private func spatialDirection(for heading: UIFocusHeading) -> StateMachine.FocusDirection? {
        switch heading {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        default: return nil
        }
    }
    #endif
}

extension UIKitFocusSystem {
    /// Dependencies required to adapt UIKit focus updates.
    struct Dependencies {
        /// The ancestor containing the native focusable Rive rendering view.
        let focusEnvironment: UIView

        init(focusEnvironment: UIView) {
            self.focusEnvironment = focusEnvironment
        }
    }
}

#endif
