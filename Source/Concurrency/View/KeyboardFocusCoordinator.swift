//
//  KeyboardFocusCoordinator.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Combine
#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit
#else
import AppKit
#endif

/// Receives readiness and lifecycle changes for a pending SwiftUI request.
@MainActor
protocol RiveUIViewKeyboardFocusDelegate: AnyObject {
    /// Allows a pending request to check readiness after attachment or discovery.
    func viewKeyboardFocusReadinessDidChange(_ view: RiveUIView)
    /// Cancels acquisition on pause, replacement, removal, or loading failure.
    func viewDidCancelKeyboardFocusRequest(_ view: RiveUIView)
}

extension RiveUIViewRepresentable {
    /// Coordinates keyboard-focus requests for both SwiftUI representables.
    @MainActor
    public final class Coordinator: RiveUIViewKeyboardFocusDelegate {
        private weak var view: RiveUIView?
        private var lastRequested = false
        private var onResult: (@MainActor (KeyboardResponderAction, Bool) -> Void)?
        private var pendingAction: KeyboardResponderAction?
        private var windowObservation: AnyCancellable?

        /// Defers the native responder transition until the SwiftUI update returns.
        private var actionTask: Task<Void, Never>?

        deinit {
            actionTask?.cancel()
        }

        /// Applies Boolean edges without replaying a consumed or cancelled request.
        ///
        /// Initial `true` and false-to-true changes make one attempt; unchanged
        /// `true` never reclaims ownership. Native transitions run after the
        /// SwiftUI update returns, and pending requests wait for readiness
        /// notifications rather than polling. Pause, content replacement, removal,
        /// and loading failure cancel a pending request without a result; requests
        /// made while paused are ignored. Resignation does not disable ordinary
        /// UIKit native focus.
        func update(
            requested: Bool, in view: RiveUIView,
            onResult: (@MainActor (KeyboardResponderAction, Bool) -> Void)? = nil
        ) {
            if self.view !== view {
                dismantle()
                self.view = view
                view.keyboardFocusDelegate = self
                lastRequested = false
            }
            self.onResult = onResult
            guard lastRequested != requested else { return }
            lastRequested = requested
            cancelPendingAction()
            guard !requested || !view.isPaused else { return }
            pendingAction = requested ? .become : .resign

            if requested {
                #if !os(macOS) || RIVE_MAC_CATALYST
                let notification = UIWindow.didBecomeKeyNotification
                #else
                let notification = NSWindow.didBecomeKeyNotification
                #endif
                windowObservation = NotificationCenter.default.publisher(for: notification)
                    .sink { [weak self] _ in
                        MainActor.assumeIsolated { self?.scheduleAction() }
                    }
            }
            scheduleAction()
        }

        /// Disconnects a disappearing representable without affecting another owner.
        func dismantle() {
            cancelPendingAction()
            if view?.keyboardFocusDelegate === self { view?.keyboardFocusDelegate = nil }
            view = nil
            onResult = nil
        }

        func viewKeyboardFocusReadinessDidChange(_ view: RiveUIView) {
            guard self.view === view else { return }
            scheduleAction()
        }

        func viewDidCancelKeyboardFocusRequest(_ view: RiveUIView) {
            guard self.view === view, pendingAction == .become else { return }
            cancelPendingAction()
        }

        private func cancelPendingAction() {
            actionTask?.cancel()
            actionTask = nil
            pendingAction = nil
            windowObservation = nil
        }

        private func scheduleAction() {
            guard actionTask == nil, let view, let action = pendingAction else { return }
            guard action == .resign || view.canRequestKeyboardFocus else { return }
            actionTask = Task { @MainActor [weak self] in
                guard !Task.isCancelled, let self else { return }
                actionTask = nil
                guard let view = self.view, let action = pendingAction else { return }
                guard action == .resign || view.canRequestKeyboardFocus else { return }
                pendingAction = nil
                windowObservation = nil
                // Native transitions can reenter updates. Report this attempt
                // through the callback that was current when it began.
                let onResult = self.onResult
                let succeeded: Bool
                switch action {
                case .become: succeeded = view.becomeKeyboardResponder()
                case .resign: succeeded = view.resignKeyboardResponder()
                }
                onResult?(action, succeeded)
            }
        }
    }
}
