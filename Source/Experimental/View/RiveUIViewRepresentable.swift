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
/// The underlying view is created exactly once; subsequent changes to `rive`, `frameRate`,
/// or `isPaused` are applied to the existing view through the update method.
@_spi(RiveExperimental)
public struct RiveUIViewRepresentable: NativeViewRepresentable, Equatable {
    private var rive: Rive?
    private var frameRate: FrameRate
    private var isPaused: Bool
    private var delegate: RiveUIViewDelegate?

    public init(rive: Rive?, delegate: RiveUIViewDelegate? = nil) {
        self.rive = rive
        self.delegate = delegate
        self.frameRate = .default
        self.isPaused = false
    }

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

    // MARK: Equatable
    nonisolated public static func ==(lhs: Self, rhs: Self) -> Bool {
        MainActor.assumeIsolated {
            lhs.rive === rhs.rive
                && lhs.frameRate == rhs.frameRate
                && lhs.isPaused == rhs.isPaused
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
/// ```swift
/// AsyncRiveUIViewRepresentable {
///     let worker = try await Worker()
///     let file = try await File(source: .local("my_file", .main), worker: worker)
///     return try await Rive(file: file)
/// }
/// ```
@_spi(RiveExperimental)
public struct AsyncRiveUIViewRepresentable: NativeViewRepresentable, Equatable {
    private var riveLoader: @MainActor () async throws -> Rive
    private var frameRate: FrameRate
    private var isPaused: Bool
    private var delegate: RiveUIViewDelegate?

    public init(rive: @MainActor @escaping () async throws -> Rive, delegate: RiveUIViewDelegate? = nil) {
        self.riveLoader = rive
        self.delegate = delegate
        self.frameRate = .default
        self.isPaused = false
    }

#if canImport(UIKit) || RIVE_MAC_CATALYST
    public func makeUIView(context: Context) -> RiveUIView {
        RiveLog.debug(tag: .view, "[RiveUIView] Creating async SwiftUI-backed view")
        return RiveUIView(rive: riveLoader, delegate: delegate, isPaused: isPaused)
    }

    public func updateUIView(_ uiView: RiveUIView, context: Context) {
        RiveLog.trace(tag: .view, "[RiveUIView] Updating async SwiftUI-backed view")
        uiView.frameRate = frameRate
        uiView.isPaused = isPaused
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

    // MARK: Equatable
    nonisolated public static func ==(lhs: Self, rhs: Self) -> Bool {
        MainActor.assumeIsolated {
            lhs.frameRate == rhs.frameRate
            && lhs.isPaused == rhs.isPaused
        }
    }
}
