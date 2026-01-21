//
//  RiveUIFile.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A class that represents a Rive file, providing asynchronous access to its data and operations.
///
/// Files can be loaded from local bundles or remote URLs, and provide access to artboards,
/// state machines, and view models contained within the Rive file.
@_spi(RiveExperimental)
public class File: Equatable {
    /// The underlying type for the file handle identifier.
    ///
    /// Handle to a file instance in the C++ runtime. Obtained from the command queue
    /// when a file is loaded via `FileService.loadFile`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `File` instance
    /// is deallocated via `FileService.deleteFile`.
    typealias FileHandle = UInt64

    /// The internal handle that identifies this file instance.
    ///
    /// This handle links this Swift object to the underlying C++ file in the runtime.
    /// It's obtained from the command queue when the file is loaded and is used for
    /// all command queue operations that reference this file.
    let fileHandle: FileHandle
    /// Dependencies required for file operations and server communication
    let dependencies: Dependencies

    let worker: Worker

    /// Creates a new File instance by loading Rive file data from the specified source.
    ///
    /// The file data is loaded asynchronously in a background thread from either a local bundle or remote URL,
    /// then parsed and made available for creating artboards and accessing file contents.
    ///
    /// - Parameters:
    ///   - source: The source containing the Rive file data (local bundle or remote URL)
    ///   - worker: The worker that will process this file
    /// - Throws: `FileError` if the file cannot be loaded or parsed
    @MainActor
    public convenience init(source: Source, worker: Worker) async throws {
        try await self.init(
            dependencies: Dependencies(
                fileLoader: FileLoader(source: source),
                fileService: FileService(
                    dependencies: .init(
                        commandQueue: worker.dependencies.workerService.dependencies.commandQueue
                    )
                ),
            ),
            worker: worker
        )
    }

    /// Creates a new File instance with custom dependencies
    /// - Parameter dependencies: The dependencies to use for this file instance
    /// - Throws: `FileError` if the file cannot be loaded
    /// - Note: This initializer is not public, and should only be used by public initializers or in tests
    @MainActor
    convenience init(dependencies: Dependencies, worker: Worker) async throws {
        let data = try await dependencies.fileLoader.load()
        let handle = try await dependencies.fileService.loadFile(data: data)
        self.init(dependencies: dependencies, fileHandle: handle, worker: worker)
    }

    /// Initializes a File with existing dependencies and file handle
    /// - Parameters:
    ///   - dependencies: The dependencies to use for this file instance
    ///   - fileHandle: The pre-loaded file handle
    /// - Note: This initializer is not public, and should only be used by other convenience initializers or in tests
    @MainActor
    init(dependencies: Dependencies, fileHandle: FileHandle, worker: Worker) {
        self.dependencies = dependencies
        self.fileHandle = fileHandle
        self.worker = worker
    }

    deinit {
        let service = dependencies.fileService
        let handle = fileHandle
        Task { @MainActor in
            service.deleteFile(handle)
        }
    }

    /// Compares two File instances for equality.
    ///
    /// Two file instances are considered equal if they reference the same underlying file handle,
    /// meaning they represent the same loaded Rive file.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side file instance
    ///   - rhs: The right-hand side file instance
    /// - Returns: `true` if both files reference the same underlying file handle
    public static func ==(lhs: File, rhs: File) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    /// Retrieves the names of all artboards contained within this Rive file.
    ///
    /// - Returns: An array of artboard names
    /// - Throws: `FileError` if the artboard names cannot be retrieved
    @MainActor
    public func getArtboardNames() async throws -> [String] {
        return try await dependencies.fileService.getArtboardNames(fileHandle: fileHandle)
    }

    /// Creates an artboard from this file.
    ///
    /// If a name is provided, creates the artboard with that specific name. If `nil` is provided,
    /// creates the default (first) artboard from the file.
    ///
    /// - Parameter name: The name of the artboard to create, or `nil` for the default artboard
    /// - Returns: A new `Artboard` instance
    /// - Throws: `FileError.invalidArtboard` if the specified artboard name does not exist
    @MainActor
    public func createArtboard(_ name: String? = nil) async throws -> Artboard {
        if let name {
            let artboardNames = try await getArtboardNames()
            guard artboardNames.contains(name) else {
                throw FileError.invalidArtboard(name)
            }
        }

        let commandQueue = worker.dependencies.workerService.dependencies.commandQueue
        return Artboard(
            name: name,
            from: fileHandle,
            dependencies: .init(
                artboardService: ArtboardService(
                    dependencies: .init(
                        commandQueue: commandQueue
                    )
                )
            )
        )
    }

    /// Creates a view model instance from this file based on the specified source.
    ///
    /// View model instances provide access to the data structure and bindings defined in the
    /// Rive file. The source determines which view model and instance to create.
    ///
    /// - Parameter source: The source specifying which view model instance to create
    /// - Returns: A new `ViewModelInstance` instance
    /// - Throws: `FileError.invalidViewModel` if the specified view model name does not exist,
    ///           `FileError.invalidViewModelInstance` if the specified instance name does not exist
    @MainActor
    public func createViewModelInstance(_ source: ViewModelInstanceSource) async throws -> ViewModelInstance {
        switch source {
        case .name(let instanceName, from: let source):
            switch source {
            case .name(let viewModelName):
                let viewModelNames = try await getViewModelNames()
                guard viewModelNames.contains(viewModelName) else {
                    throw FileError.invalidViewModel(viewModelName)
                }
                let instanceNames = try await getInstanceNames(of: viewModelName)
                guard instanceNames.contains(instanceName) else {
                    throw FileError.invalidViewModelInstance(instanceName)
                }
            case .artboardDefault:
                break
            }
        case .blank,
        .viewModelDefault:
            break
        }
        let commandQueue = worker.dependencies.workerService.dependencies.commandQueue
        return ViewModelInstance(
            source: source,
            from: self,
            dependencies: .init(
                viewModelInstanceService: .init(
                    dependencies: .init(
                        commandQueue: commandQueue
                    )
                )
            )
        )
    }

    /// Retrieves the names of all view models defined in this Rive file.
    ///
    /// View models define the data structure and bindings for artboards. This method
    /// allows discovery of all available view models in the file.
    ///
    /// - Returns: An array of view model names
    /// - Throws: `FileError` if the view model names cannot be retrieved
    @MainActor
    public func getViewModelNames() async throws -> [String] {
        return try await dependencies.fileService.getViewModelNames(fileHandle: fileHandle)
    }

    /// Retrieves the names of all instances for a specific view model.
    ///
    /// A view model can have multiple instances, each representing a different configuration
    /// or state of the same data structure.
    ///
    /// - Parameter viewModel: The name of the view model to query
    /// - Returns: An array of instance names for the specified view model
    /// - Throws: `FileError` if the instance names cannot be retrieved
    @MainActor
    public func getInstanceNames(of viewModel: String) async throws -> [String] {
        return try await dependencies.fileService.getInstanceNames(of: viewModel, from: fileHandle)
    }

    /// Retrieves the property definitions for a specific view model.
    ///
    /// Properties define the data fields available in a view model instance, including
    /// their types, names, and optional metadata.
    ///
    /// - Parameter viewModel: The name of the view model to query
    /// - Returns: An array of `ViewModelProperty` instances describing each property
    /// - Throws: `FileError` if the request fails, `ViewModelPropertyError` if property parsing fails
    @MainActor
    public func getProperties(of viewModel: String) async throws -> [ViewModelProperty] {
        return try await dependencies.fileService.getProperties(of: viewModel, from: fileHandle)
    }

    /// Retrieves all enum definitions defined in this Rive file.
    ///
    /// Enums define named sets of string values that can be used as property types in view models.
    ///
    /// - Returns: An array of `ViewModelEnum` instances, each containing the enum name and its values
    /// - Throws: `FileError` if the request fails, `ViewModelEnumError` if enum parsing fails
    @MainActor
    public func getViewModelEnums() async throws -> [ViewModelEnum] {
        return try await dependencies.fileService.getViewModelEnums(from: fileHandle)
    }

    /// Retrieves the default view model information for an artboard.
    ///
    /// View models define the data structure and bindings for an artboard. This method
    /// allows discovery of which view model and instance are associated with the artboard by default.
    ///
    /// - Parameter artboard: The artboard to query for default view model information
    /// - Returns: A tuple containing the view model name and instance name
    /// - Throws: `ArtboardError` if the request fails
    @MainActor
    public func getDefaultViewModelInfo(for artboard: Artboard) async throws -> (viewModelName: String, instanceName: String) {
        return try await artboard.getDefaultViewModelInfo(parent: self)
    }
}

extension File {
    /// Container for all dependencies required by a File instance.
    struct Dependencies {
        /// Handles loading of Rive file data from various sources.
        /// Does not interact with the command queue; only handles data retrieval.
        let fileLoader: FileLoaderProtocol
        /// Provides file-level services via command queue interactions.
        /// Implements `FileListener` to receive callbacks from the command server.
        let fileService: FileService
    }
}
