//
//  UIKitFocusSystem.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

/// Coordinates native entry and exit for Rive's UIKit focus item.
@MainActor
final class UIKitFocusSystem: FocusSystem {
    /// The controller that handles translated UIKit focus events.
    weak var delegate: (any FocusSystemDelegate)?

    /// Whether UIKit should include the Rive rendering view in focus traversal.
    var isFocusable = false

    /// tvOS needs a starting node for remote navigation and Select.
    var defaultEntryDirection: FocusTraversalDirection? {
        #if os(tvOS)
        return .next
        #else
        return nil
        #endif
    }

    /// The ancestor that defines the native Rive focus environment.
    private weak var focusEnvironment: UIView?

    /// Indicates that the system has permanently stopped handling focus.
    private var isInvalidated = false

    #if os(tvOS)
    /// Reuses a traversal decision while UIKit synchronously retries native
    /// destinations for the same directional movement.
    private var navigationDecision: (direction: StateMachine.FocusDirection, handled: Bool)?
    #endif

    init(dependencies: Dependencies) {
        focusEnvironment = dependencies.focusEnvironment
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
        guard !isInvalidated else { return }
        isInvalidated = true
        delegate = nil
    }

    func shouldUpdateFocus(
        from previouslyFocusedItem: (any UIFocusItem)?,
        to nextFocusedItem: (any UIFocusItem)?,
        heading: UIFocusHeading
    ) -> Bool {
        guard !isInvalidated, isFocusable, let focusEnvironment else { return true }
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
    }

    func didUpdateFocus(
        from previouslyFocusedItem: (any UIFocusItem)?,
        to nextFocusedItem: (any UIFocusItem)?,
        heading: UIFocusHeading
    ) {
        guard !isInvalidated, let focusEnvironment else { return }
        let wasInsideRive = isFocusItem(previouslyFocusedItem, within: focusEnvironment)
        let isInsideRive = isFocusItem(nextFocusedItem, within: focusEnvironment)
        guard wasInsideRive != isInsideRive else { return }

        if wasInsideRive {
            delegate?.focusSystemDidExit(self)
            return
        }

        guard isFocusable else { return }
        delegate?.focusSystem(self, didEnter: traversalDirection(for: heading))
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
        guard !isInvalidated, isFocusable, let focusEnvironment,
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
