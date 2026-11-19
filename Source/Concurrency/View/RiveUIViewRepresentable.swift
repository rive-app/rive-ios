//
//  RiveUIViewRepresentable.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/25/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI

/// A SwiftUI view representable that wraps a `RiveUIView` for use in SwiftUI.
///
/// This struct creates and owns a `RiveUIView` internally via `makeUIView` / `makeNSView`,
/// and syncs configuration in `updateUIView` / `updateNSView` whenever SwiftUI re-renders.
/// The underlying view is created once per SwiftUI identity; subsequent configuration
/// changes are applied to the existing view through the update method.
///
/// Authored focus nodes enable native traversal after loading and focus discovery.
/// Ordinary native traversal does not require SwiftUI's `focusable(_:)` modifier.
public struct RiveUIViewRepresentable: NativeViewRepresentable, Equatable {
    /// The keyboard-responder operation attempted by ``keyboardFocused(_:onResult:)``.
    public enum KeyboardResponderAction: Equatable, Sendable {
        /// Attempts to acquire keyboard-responder ownership.
        case become
        /// Attempts to release keyboard-responder ownership.
        case resign
    }

    private var rive: Rive?
    private var frameRate: FrameRate
    private var isPaused: Bool
    private var keyboardFocusRequested = false
    private var keyboardFocusResultHandler: KeyboardFocusResultHandler?
    private var delegate: RiveUIViewDelegate?
    #if !os(macOS) || RIVE_MAC_CATALYST
    private var semantics: Semantics = RiveUIView.Constants.Defaults.semantics
    #endif

    public init(rive: Rive?, delegate: RiveUIViewDelegate? = nil) {
        self.rive = rive
        self.delegate = delegate
        self.frameRate = RiveUIView.Constants.Defaults.frameRate
        self.isPaused = RiveUIView.Constants.Defaults.isPaused
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

#if canImport(UIKit) || RIVE_MAC_CATALYST
    public func makeUIView(context: Context) -> RiveUIView {
        RiveLog.debug(tag: .view, "[RiveUIView] Creating SwiftUI-backed view")
        return RiveUIView(rive: rive, delegate: delegate, isPaused: isPaused)
    }

    public func updateUIView(_ uiView: RiveUIView, context: Context) {
        RiveLog.trace(tag: .view, "[RiveUIView] Updating SwiftUI-backed view")
        uiView.rive = rive
        uiView.frameRate = frameRate
        uiView.isPaused = isPaused
        uiView.semantics = semantics
        context.coordinator.update(
            requested: keyboardFocusRequested, in: uiView,
            onResult: keyboardFocusResultHandler?.callback
        )
    }

    public static func dismantleUIView(_ uiView: RiveUIView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
#else
    public func makeNSView(context: Context) -> RiveUIView {
        RiveLog.debug(tag: .view, "[RiveUIView] Creating SwiftUI-backed view")
        return RiveUIView(rive: rive, delegate: delegate, isPaused: isPaused)
    }

    public func updateNSView(_ nsView: RiveUIView, context: Context) {
        RiveLog.trace(tag: .view, "[RiveUIView] Updating SwiftUI-backed view")
        nsView.rive = rive
        nsView.frameRate = frameRate
        nsView.isPaused = isPaused
        context.coordinator.update(
            requested: keyboardFocusRequested, in: nsView,
            onResult: keyboardFocusResultHandler?.callback
        )
    }

    public static func dismantleNSView(_ nsView: RiveUIView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
#endif

    public func frameRate(_ frameRate: FrameRate) -> Self {
        var copy = self
        copy.frameRate = frameRate
        return copy
    }

    public func paused(_ isPaused: Bool) -> Self {
        var copy = self
        copy.isPaused = isPaused
        return copy
    }

    /// Makes the view the keyboard responder once its content is ready, so
    /// authored keyboard input works without the user first tabbing into the view.
    ///
    /// Each change to `true` makes one request once the content is loaded, in
    /// the key window, and ready with authored focus nodes; a change made while
    /// the view is paused makes no request. The view then focuses the graphic's
    /// first authored focus node, unless a node is already focused. A change to
    /// `false` cancels a pending request or relinquishes ownership. This does not
    /// enable text input or present a software keyboard, and it doesn't report
    /// later focus changes.
    ///
    /// Avoid combining this modifier with SwiftUI's `focused(_:)` on the same view.
    ///
    /// - Parameters:
    ///   - requested: Whether the view should be the keyboard responder.
    ///   - onResult: Called on the main actor after each attempt, with the
    ///     attempted action and whether it succeeded. Requests cancelled before
    ///     they run, such as when the view is paused or removed, don't report a
    ///     result.
    public func keyboardFocused(
        _ requested: Bool,
        onResult: (@MainActor (_ action: KeyboardResponderAction, _ succeeded: Bool) -> Void)? = nil
    ) -> Self {
        var copy = self
        copy.keyboardFocusRequested = requested
        copy.keyboardFocusResultHandler = onResult.map(KeyboardFocusResultHandler.init)
        return copy
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    /// Sets the VoiceOver accessibility semantics mode for this Rive view.
    public func semantics(_ semantics: Semantics) -> Self {
        var copy = self
        copy.semantics = semantics
        return copy
    }
    #endif

    // MARK: Equatable
    nonisolated public static func ==(lhs: Self, rhs: Self) -> Bool {
        MainActor.assumeIsolated {
            var isEqual = lhs.rive === rhs.rive
                && lhs.frameRate == rhs.frameRate
                && lhs.isPaused == rhs.isPaused
                && lhs.keyboardFocusRequested == rhs.keyboardFocusRequested
                && lhs.keyboardFocusResultHandler === rhs.keyboardFocusResultHandler
            #if !os(macOS) || RIVE_MAC_CATALYST
            isEqual = isEqual && lhs.semantics == rhs.semantics
            #endif
            return isEqual
        }
    }
}

/// A SwiftUI view representable that asynchronously loads a Rive configuration.
///
/// Use this when the `Rive` instance isn't available synchronously — for example,
/// when loading from a network URL or performing other async setup. The closure
/// runs once when the view is created. To force a reload (e.g. when a URL changes),
/// apply `.id(url)` to the view.
///
/// Authored focus nodes enable native traversal after loading and focus discovery.
/// Ordinary native traversal does not require SwiftUI's `focusable(_:)` modifier.
///
/// ```swift
/// AsyncRiveUIViewRepresentable {
///     let worker = try await Worker()
///     let file = try await File(source: .local("my_file", .main), worker: worker)
///     return try await Rive(file: file)
/// }
/// ```
public struct AsyncRiveUIViewRepresentable: NativeViewRepresentable, Equatable {
    public typealias Coordinator = RiveUIViewRepresentable.Coordinator
    /// The keyboard-responder action shared by both representables.
    public typealias KeyboardResponderAction = RiveUIViewRepresentable.KeyboardResponderAction

    private var riveLoader: @MainActor () async throws -> Rive
    private var frameRate: FrameRate
    private var isPaused: Bool
    private var keyboardFocusRequested = false
    private var keyboardFocusResultHandler: KeyboardFocusResultHandler?
    private var delegate: RiveUIViewDelegate?
    #if !os(macOS) || RIVE_MAC_CATALYST
    private var semantics: Semantics = RiveUIView.Constants.Defaults.semantics
    #endif

    public init(rive: @MainActor @escaping () async throws -> Rive, delegate: RiveUIViewDelegate? = nil) {
        self.riveLoader = rive
        self.delegate = delegate
        self.frameRate = RiveUIView.Constants.Defaults.frameRate
        self.isPaused = RiveUIView.Constants.Defaults.isPaused
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

#if canImport(UIKit) || RIVE_MAC_CATALYST
    public func makeUIView(context: Context) -> RiveUIView {
        RiveLog.debug(tag: .view, "[RiveUIView] Creating async SwiftUI-backed view")
        return RiveUIView(rive: riveLoader, delegate: delegate, isPaused: isPaused)
    }

    public func updateUIView(_ uiView: RiveUIView, context: Context) {
        RiveLog.trace(tag: .view, "[RiveUIView] Updating async SwiftUI-backed view")
        uiView.frameRate = frameRate
        uiView.isPaused = isPaused
        uiView.semantics = semantics
        context.coordinator.update(
            requested: keyboardFocusRequested, in: uiView,
            onResult: keyboardFocusResultHandler?.callback
        )
    }

    public static func dismantleUIView(_ uiView: RiveUIView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
#else
    public func makeNSView(context: Context) -> RiveUIView {
        RiveLog.debug(tag: .view, "[RiveUIView] Creating async SwiftUI-backed view")
        return RiveUIView(rive: riveLoader, delegate: delegate, isPaused: isPaused)
    }

    public func updateNSView(_ nsView: RiveUIView, context: Context) {
        RiveLog.trace(tag: .view, "[RiveUIView] Updating async SwiftUI-backed view")
        nsView.frameRate = frameRate
        nsView.isPaused = isPaused
        context.coordinator.update(
            requested: keyboardFocusRequested, in: nsView,
            onResult: keyboardFocusResultHandler?.callback
        )
    }

    public static func dismantleNSView(_ nsView: RiveUIView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
#endif

    public func frameRate(_ frameRate: FrameRate) -> Self {
        var copy = self
        copy.frameRate = frameRate
        return copy
    }

    public func paused(_ isPaused: Bool) -> Self {
        var copy = self
        copy.isPaused = isPaused
        return copy
    }

    /// Makes the view the keyboard responder once its content is ready, so
    /// authored keyboard input works without the user first tabbing into the view.
    ///
    /// Each change to `true` makes one request once the content is loaded, in
    /// the key window, and ready with authored focus nodes; a change made while
    /// the view is paused makes no request. The view then focuses the graphic's
    /// first authored focus node, unless a node is already focused. A change to
    /// `false` cancels a pending request or relinquishes ownership. This does not
    /// enable text input or present a software keyboard, and it doesn't report
    /// later focus changes.
    ///
    /// Avoid combining this modifier with SwiftUI's `focused(_:)` on the same view.
    ///
    /// - Parameters:
    ///   - requested: Whether the view should be the keyboard responder.
    ///   - onResult: Called on the main actor after each attempt, with the
    ///     attempted action and whether it succeeded. Requests cancelled before
    ///     they run, such as when the view is paused or removed, don't report a
    ///     result.
    public func keyboardFocused(
        _ requested: Bool,
        onResult: (@MainActor (_ action: KeyboardResponderAction, _ succeeded: Bool) -> Void)? = nil
    ) -> Self {
        var copy = self
        copy.keyboardFocusRequested = requested
        copy.keyboardFocusResultHandler = onResult.map(KeyboardFocusResultHandler.init)
        return copy
    }

    #if !os(macOS) || RIVE_MAC_CATALYST
    /// Sets the VoiceOver accessibility semantics mode for this Rive view.
    public func semantics(_ semantics: Semantics) -> Self {
        var copy = self
        copy.semantics = semantics
        return copy
    }
    #endif

    // MARK: Equatable
    nonisolated public static func ==(lhs: Self, rhs: Self) -> Bool {
        MainActor.assumeIsolated {
            var isEqual = lhs.frameRate == rhs.frameRate
                && lhs.isPaused == rhs.isPaused
                && lhs.keyboardFocusRequested == rhs.keyboardFocusRequested
                && lhs.keyboardFocusResultHandler === rhs.keyboardFocusResultHandler
            #if !os(macOS) || RIVE_MAC_CATALYST
            isEqual = isEqual && lhs.semantics == rhs.semantics
            #endif
            return isEqual
        }
    }
}

/// Gives callbacks a stable identity across representable copies. A new callback
/// must update the coordinator even when the requested focus value is unchanged.
private final class KeyboardFocusResultHandler {
    let callback: @MainActor (RiveUIViewRepresentable.KeyboardResponderAction, Bool) -> Void

    init(_ callback: @escaping @MainActor (RiveUIViewRepresentable.KeyboardResponderAction, Bool) -> Void) {
        self.callback = callback
    }
}
