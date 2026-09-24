//
//  Configuration.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/23/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import Combine

/// A class that combines the components and presentation options needed to render Rive content.
///
/// A Rive object manages the relationship between a file, artboard, and state machine and provides
/// properties for controlling how the artboard is displayed, including fit mode and background color.
@MainActor
public final class Rive: ObservableObject, Equatable {
    /// The Rive file containing the artboard and state machine.
    public let file: File
    /// The artboard to render.
    public let artboard: Artboard
    /// The state machine that controls animations and state transitions.
    public let stateMachine: StateMachine
    /// The main view model instance supplied or created by the deprecated initializer with `dataBind`.
    ///
    /// Returns `nil` when using an initializer without `dataBind`. Create, retain, and explicitly
    /// bind view model instances when you need to read or modify their properties.
    @available(*, deprecated, message: "viewModelInstance will be removed in a future release. Create and retain a view model instance, then bind it explicitly to access its properties.")
    public var viewModelInstance: ViewModelInstance? {
        return legacyViewModelInstance
    }
    /// The background color to use when rendering the artboard.
    public var backgroundColor: Color {
        didSet {
            backgroundColorDidChange.send(backgroundColor)
        }
    }
    /// The fit mode that determines how the artboard is scaled and positioned within its bounds.
    public var fit: Fit {
        didSet {
            fitDidChange.send(fit)
        }
    }

    private var legacyViewModelInstance: ViewModelInstance?

    // Publishers for various mutable properties, so that RiveUIView can
    // listen to these changes and react appropriately
    let backgroundColorDidChange = PassthroughSubject<Color, Never>()
    let fitDidChange = PassthroughSubject<Fit, Never>()

    /// Creates a Rive object with the specified components and legacy data-binding behavior.
    ///
    /// - Parameters:
    ///   - file: The Rive file containing the artboard and state machine
    ///   - artboard: The artboard to render
    ///   - stateMachine: The state machine that controls animations
    ///   - dataBind: How data binding should be initialized
    ///   - fit: The fit mode for scaling and positioning, defaults to `.contain(alignment: .center)`
    ///   - backgroundColor: The background color, defaults to clear
    @available(*, deprecated, message: "This initializer will be removed in a future release. Use a Rive initializer without dataBind. Retain and explicitly bind view model instances you need to access.")
    @MainActor
    public init(
        file: File,
        artboard: Artboard? = nil,
        stateMachine: StateMachine? = nil,
        dataBind: DataBind = .auto,
        fit: Fit = .contain(alignment: .center),
        backgroundColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0),
    ) async throws {
        self.file = file
        self.artboard = try await Self.resolveArtboard(artboard, for: file)
        self.stateMachine = try await Self.resolveStateMachine(stateMachine, for: self.artboard)
        self.fit = fit
        self.backgroundColor = backgroundColor

        switch dataBind {
        case .auto:
            RiveLog.debug(tag: .rive, "[Rive] Resolving data binding mode: auto")
            if let instance = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(self.artboard))) {
                RiveLog.debug(tag: .rive, "[Rive] Binding auto-resolved view model instance")
                try await self.stateMachine.bindViewModelInstances(main: instance)
                legacyViewModelInstance = instance
            } else {
                RiveLog.warning(tag: .rive, "[Rive] Auto data binding did not resolve a default view model instance")
            }
        case .instance(let instance):
            RiveLog.debug(tag: .rive, "[Rive] Resolving data binding mode: instance")
            RiveLog.debug(tag: .rive, "[Rive] Binding provided view model instance")
            try await self.stateMachine.bindViewModelInstances(main: instance)
            legacyViewModelInstance = instance
        case .none:
            RiveLog.debug(tag: .rive, "[Rive] Resolving data binding mode: none")
            break
        }
    }

    /// Creates a Rive object using the default artboard and state machine.
    ///
    /// The state machine binds its authored default view model instances during creation.
    /// These default instances cannot be retrieved. To observe or modify view model instances,
    /// create an artboard from the file, create a state machine from that artboard, and bind
    /// instances you retain. Then use the initializer that accepts the explicit artboard and
    /// state machine.
    ///
    /// - Parameters:
    ///   - file: The Rive file containing the artboard and state machine
    ///   - fit: The fit mode for scaling and positioning, defaults to `.contain(alignment: .center)`
    ///   - backgroundColor: The background color, defaults to clear
    @MainActor
    public convenience init(
        file: File,
        fit: Fit = .contain(alignment: .center),
        backgroundColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0)
    ) async throws {
        let artboard = try await file.createArtboard()
        let stateMachine = try await artboard.createStateMachine()
        try await self.init(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            fit: fit,
            backgroundColor: backgroundColor
        )
    }

    /// Creates a Rive object using the specified artboard and its default state machine.
    ///
    /// The default state machine binds its authored default view model instances during creation.
    /// These default instances cannot be retrieved. To observe or modify view model instances,
    /// create a state machine, bind instances you retain, and use the initializer that accepts
    /// an explicit state machine.
    ///
    /// - Parameters:
    ///   - file: The Rive file containing the artboard
    ///   - artboard: The artboard to render
    ///   - fit: The fit mode for scaling and positioning, defaults to `.contain(alignment: .center)`
    ///   - backgroundColor: The background color, defaults to clear
    @MainActor
    public convenience init(
        file: File,
        artboard: Artboard,
        fit: Fit = .contain(alignment: .center),
        backgroundColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0)
    ) async throws {
        let stateMachine = try await artboard.createStateMachine()
        try await self.init(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            fit: fit,
            backgroundColor: backgroundColor
        )
    }

    /// Creates a Rive object using the specified artboard and state machine.
    ///
    /// The supplied state machine is used as configured and is not rebound during initialization.
    /// To read or modify properties of view model instances bound to the supplied state machine,
    /// retain references to those instances when binding them.
    ///
    /// - Parameters:
    ///   - file: The Rive file containing the artboard and state machine
    ///   - artboard: The artboard to render
    ///   - stateMachine: The state machine that controls animations
    ///   - fit: The fit mode for scaling and positioning, defaults to `.contain(alignment: .center)`
    ///   - backgroundColor: The background color, defaults to clear
    @MainActor
    public init(
        file: File,
        artboard: Artboard,
        stateMachine: StateMachine,
        fit: Fit = .contain(alignment: .center),
        backgroundColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0)
    ) async throws {
        self.file = file
        self.artboard = artboard
        self.stateMachine = stateMachine
        self.fit = fit
        self.backgroundColor = backgroundColor
    }

    nonisolated public static func ==(lhs: Rive, rhs: Rive) -> Bool {
        if lhs === rhs {
            return true
        }

        return MainActor.assumeIsolated {
            return lhs.file == rhs.file
            && lhs.artboard == rhs.artboard
            && lhs.stateMachine == rhs.stateMachine
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.fit == rhs.fit
        }
    }

    // MARK: - Private

    /// Helper function to resolve an artboard from a file, creating the default if needed.
    @MainActor
    private static func resolveArtboard(_ artboard: Artboard?, for file: File) async throws -> Artboard {
        if let artboard {
            return artboard
        } else {
            return try await file.createArtboard()
        }
    }

    /// Helper function to resolve a state machine from an artboard, creating the default if needed.
    @MainActor
    private static func resolveStateMachine(_ stateMachine: StateMachine?, for artboard: Artboard) async throws -> StateMachine {
        if let stateMachine {
            return stateMachine
        } else {
            return try await artboard.instantiateStateMachine()
        }
    }
}
