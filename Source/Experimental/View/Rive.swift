//
//  Configuration.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/23/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import Combine

/// A class that represents a complete Rive configuration for rendering.
///
/// Rive combines a file, artboard, and state machine into a single configuration that can be
/// used for rendering. It manages the relationship between these components and provides
/// properties for controlling how the artboard is displayed, including fit mode and background color.
@_spi(RiveExperimental)
public class Rive: ObservableObject {
    /// The Rive file containing the artboard and state machine.
    public var file: File
    /// The artboard to render.
    public var artboard: Artboard
    /// The state machine that controls animations and state transitions.
    public var stateMachine: StateMachine
    /// The view model instance that handles data binding in the state machine.
    /// This is the result of processing the dataBind argument when initializing a Rive object.
    public var viewModelInstance: ViewModelInstance?
    /// The background color to use when rendering the artboard.
    public var backgroundColor: Color
    /// The fit mode that determines how the artboard is scaled and positioned within its bounds.
    public var fit: Fit {
        didSet {
            fitDidChange.send(fit)
        }
    }
    let fitDidChange = PassthroughSubject<Fit, Never>()

    /// Creates a new Rive configuration with the specified components.
    ///
    /// - Parameters:
    ///   - file: The Rive file containing the artboard and state machine
    ///   - artboard: The artboard to render
    ///   - stateMachine: The state machine that controls animations
    ///   - dataBind: How data binding should be initialized
    ///   - fit: The fit mode for scaling and positioning, defaults to `.contain(alignment: .center)`
    ///   - backgroundColor: The background color, defaults to clear
    @MainActor
    public init(
        file: File,
        artboard: Artboard? = nil,
        stateMachine: StateMachine? = nil,
        dataBind: DataBind = .auto,
        fit: Fit = .contain(alignment: .center),
        backgroundColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0)
    ) async throws {
        self.file = file
        self.artboard = try await Self.resolveArtboard(artboard, for: file)
        self.stateMachine = try await Self.resolveStateMachine(stateMachine, for: self.artboard)
        self.fit = fit
        self.backgroundColor = backgroundColor

        switch dataBind {
        case .auto:
            if let instance = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(self.artboard))) {
                self.viewModelInstance = instance
                self.stateMachine.bindViewModelInstance(instance)
            }
        case .instance(let instance):
            self.viewModelInstance = instance
            self.stateMachine.bindViewModelInstance(instance)
        case .none:
            break
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
            return try await artboard.createStateMachine()
        }
    }
}
