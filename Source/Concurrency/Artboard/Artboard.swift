//
//  RiveUIArtboard.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a Rive artboard, providing access to its data and operations.
///
/// Artboards are the top-level containers in Rive files that hold all the graphics, animations,
/// and state machines. Each artboard can have multiple state machines and can be rendered
/// independently.
public final class Artboard: Equatable {
    /// The underlying type for the artboard handle identifier.
    ///
    /// Handle to an artboard instance in the C++ runtime. Obtained from the command queue
    /// when an artboard is created via `ArtboardService.createArtboard`, and used in all
    /// subsequent command queue operations. Automatically cleaned up when this `Artboard`
    /// instance is deallocated via `ArtboardService.deleteArtboard`.
    typealias ArtboardHandle = UInt64

    /// The internal handle that identifies this artboard instance.
    let artboardHandle: ArtboardHandle

    /// The dependencies required for artboard operations.
    let dependencies: Dependencies

    private static func logContext(for handle: ArtboardHandle) -> String {
        "[Artboard (\(handle))]"
    }

    /// Initializes an Artboard with an artboard handle
    ///
    /// This initializer is used internally when an artboard handle has already been
    /// created, typically by the artboard service or in test scenarios.
    ///
    /// - Parameters:
    ///   - dependencies: The dependencies required for artboard operations.
    ///   - artboardHandle: The pre-created artboard handle.
    ///
    /// - Note: This initializer is not public, and should only be used by File or in tests.
    @MainActor
    init(dependencies: Dependencies, artboardHandle: ArtboardHandle) {
        self.dependencies = dependencies
        self.artboardHandle = artboardHandle
    }

    deinit {
        let service = dependencies.artboardService
        let handle = artboardHandle
        RiveLog.debug(tag: .artboard, "\(Self.logContext(for: handle)) Deinitializing artboard; scheduling cleanup")
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteArtboard(handle) else { return }
            service.deleteArtboardListener(deletedHandle)
        }
    }

    /// Compares two Artboard instances for equality.
    ///
    /// Two artboard instances are considered equal if they reference the same underlying
    /// artboard handle. This means they represent the same artboard in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side artboard instance.
    ///   - rhs: The right-hand side artboard instance.
    /// - Returns: `true` if both artboards reference the same underlying artboard handle.
    public static func ==(lhs: Artboard, rhs: Artboard) -> Bool {
        return lhs.artboardHandle == rhs.artboardHandle
    }

    /// Retrieves the names of all state machines available on this artboard.
    ///
    /// State machines manage complex animation states and transitions between them.
    /// This method allows discovery of what state machines are available for interaction.
    ///
    /// - Returns: An array of state machine names available on this artboard
    /// - Throws: `ArtboardError` if the request fails
    @MainActor
    public func getStateMachineNames() async throws -> [String] {
        return try await dependencies.artboardService.getStateMachineNames(from: artboardHandle)
    }

    /// Creates a state machine from this artboard.
    ///
    /// If a name is provided, creates the state machine with that specific name. If `nil` is provided,
    /// creates the default state machine from the artboard.
    ///
    /// - Parameter name: The name of the state machine to create, or `nil` for the default state machine
    /// - Returns: A new `StateMachine` instance
    /// - Throws: `ArtboardError.invalidStateMachine` if the specified state machine name does not exist
    @MainActor
    public func createStateMachine(_ name: String? = nil) async throws -> StateMachine {
        let logContext = Self.logContext(for: artboardHandle)
        if let name {
            RiveLog.debug(tag: .artboard, "\(logContext) Creating state machine '\(name)'")
        } else {
            RiveLog.debug(tag: .artboard, "\(logContext) Creating default state machine")
        }
        let stateMachineService = StateMachineService(
            dependencies: .init(
                commandQueue: dependencies.artboardService.dependencies.commandQueue,
                messageGate: dependencies.artboardService.dependencies.messageGate
            )
        )
        let handle = try await dependencies.artboardService.instantiateStateMachine(
            name: name,
            artboardHandle: artboardHandle,
            observer: stateMachineService
        )
        return StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: handle
        )
    }

    // MARK: - Internal Methods

    /// Retrieves the default view model information for this artboard.
    ///
    /// This method asynchronously queries the artboard for its default view model name
    /// and instance name using the command queue.
    ///
    /// View models define the data structure and bindings for an artboard. This method
    /// allows clients to discover which view model and instance are associated with
    /// this artboard by default.
    ///
    /// - Parameter file: The file containing the Rive file data.
    /// - Returns: A tuple containing the view model name and instance name.
    /// - Throws: `ArtboardError` if the request fails.
    @MainActor
    func getDefaultViewModelInfo(parent file: File) async throws -> (viewModelName: String, instanceName: String) {
        return try await dependencies.artboardService.getDefaultViewModelInfo(from: artboardHandle, file: file.fileHandle)
    }

    @MainActor
    func setSize(_ size: CGSize, scale: Float = 1) {
        dependencies.artboardService.setSize(of: artboardHandle, size: size, scale: scale)
    }

    @MainActor
    func resetSize() {
        dependencies.artboardService.resetSize(of: artboardHandle)
    }
}

extension Artboard {
    /// Container for all dependencies required by an Artboard instance.
    struct Dependencies {
        /// Provides artboard-level services via command queue interactions.
        /// Implements `ArtboardListener` to receive callbacks from the command server.
        let artboardService: ArtboardService
    }
}
