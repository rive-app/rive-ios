//
//  RiveUIFileService.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages loading and receiving file updates via command queue.
///
/// Implements `FileListener` to receive callbacks from the command queue. Manages continuations
/// for async operations, storing them by request ID and resuming them when listener callbacks
/// are invoked. All command queue operations must be performed on the main thread (either marked
/// `@MainActor` or dispatched to the main queue). Listener callbacks are dispatched to the
/// main actor to safely access continuations.
@MainActor
class FileService: NSObject, FileListener {
    /// The dependencies required for file service operations.
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to their corresponding continuations.
    ///
    /// Continuations are stored when command queue functions are called and resumed when
    /// listener callbacks are invoked. Access must be on the main thread.
    private var continuations: [UInt64: AnyContinuation] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
    }

    /// Loads a Rive file asynchronously from the provided data.
    ///
    /// Creates a request ID, stores the continuation, and delegates to the command queue.
    /// The continuation is resumed when `onFileLoaded` or `onFileError` is called.
    ///
    /// - Parameter data: The raw data of the Rive file to load
    /// - Returns: A `File.FileHandle` that can be used to access the loaded file
    /// - Throws: `FileError.invalidFile` if the file cannot be loaded or parsed
    @MainActor
    func loadFile(data: Data) async throws -> File.FileHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.loadFile(data, observer: self, requestID: requestID)
        }
    }

    /// Requests artboard names for a loaded file asynchronously.
    ///
    /// The continuation is resumed when `onArtboardsListed` is called.
    ///
    /// - Parameter fileHandle: The file handle for the loaded file
    /// - Returns: An array of artboard names in the file
    /// - Throws: `FileError` if the request fails
    @MainActor
    func getArtboardNames(fileHandle: File.FileHandle) async throws -> [String] {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestArtboardNames(fileHandle, requestID: requestID)
        }
    }

    /// Requests view model names for a loaded file asynchronously.
    ///
    /// The continuation is resumed when `onViewModelsListed` is called.
    ///
    /// - Parameter fileHandle: The file handle for the loaded file
    /// - Returns: An array of view model names in the file
    /// - Throws: `FileError` if the request fails
    @MainActor
    func getViewModelNames(fileHandle: File.FileHandle) async throws -> [String] {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelNames(fileHandle, requestID: requestID)
        }
    }

    /// Requests instance names for a view model asynchronously.
    ///
    /// The continuation is resumed when `onViewModelInstanceNamesListed` is called.
    ///
    /// - Parameters:
    ///   - viewModelName: The name of the view model
    ///   - fileHandle: The file handle for the loaded file
    /// - Returns: An array of instance names for the view model
    /// - Throws: `FileError` if the request fails
    @MainActor
    func getInstanceNames(of viewModelName: String, from fileHandle: File.FileHandle) async throws -> [String] {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelInstanceNames(fileHandle, viewModelName: viewModelName, requestID: requestID)
        }
    }

    /// Requests property definitions for a view model asynchronously.
    ///
    /// The continuation is resumed when `onViewModelPropertiesListed` is called.
    ///
    /// - Parameters:
    ///   - viewModelName: The name of the view model
    ///   - fileHandle: The file handle for the loaded file
    /// - Returns: An array of `ViewModelProperty` instances describing each property
    /// - Throws: `FileError` if the request fails, `ViewModelPropertyError` if property parsing fails
    @MainActor
    func getProperties(of viewModelName: String, from fileHandle: File.FileHandle) async throws -> [ViewModelProperty] {
        let commandQueue = dependencies.commandQueue
        let properties: [ViewModelProperty] = try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelPropertyDefinitions(fileHandle, viewModelName: viewModelName, requestID: requestID)
        }
        return properties
    }

    /// Requests enum definitions for a file asynchronously.
    ///
    /// The continuation is resumed when `onViewModelEnumsListed` is called.
    ///
    /// - Parameter fileHandle: The file handle for the loaded file
    /// - Returns: An array of `ViewModelEnum` instances
    /// - Throws: `FileError` if the request fails, `ViewModelEnumError` if enum parsing fails
    @MainActor
    func getViewModelEnums(from fileHandle: File.FileHandle) async throws -> [ViewModelEnum] {
        let commandQueue = dependencies.commandQueue
        let enums: [ViewModelEnum] = try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.requestViewModelEnums(fileHandle, requestID: requestID)
        }
        return enums
    }

    /// Called when a file loading operation completes successfully.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the file handle.
    ///
    /// - Parameters:
    ///   - handle: The file handle for the loaded file
    ///   - requestID: The request ID matching the one used when calling `commandQueue.loadFile`
    nonisolated func onFileLoaded(_ handle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(handle))
        }
    }

    /// Called when a file deletion operation completes.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to
    /// resume the continuation associated with the delete request.
    nonisolated func onFileDeleted(_ handle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(handle))
        }
    }

    /// Called when a file loading operation encounters an error.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with a `FileError.invalidFile` error.
    ///
    /// - Parameters:
    ///   - fileHandle: The file handle that was being loaded when the error occurred
    ///   - requestID: The request ID matching the one used when calling `commandQueue.loadFile`
    ///   - message: Error message from the C++ runtime
    nonisolated func onFileError(_ fileHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .failure(FileError.invalidFile(message)))
        }
    }

    /// Called when artboard names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the artboard names.
    nonisolated func onArtboardsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(names))
        }
    }

    /// Called when view model names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the view model names.
    nonisolated func onViewModelsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(names))
        }
    }

    /// Called when view model instance names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the instance names.
    nonisolated func onViewModelInstanceNamesListed(_ fileHandle: UInt64, requestID: UInt64, viewModelName: String, names: [String]) {
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(names))
        }
    }

    /// Called when view model properties are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with property dictionaries that are parsed into `ViewModelProperty` instances.
    nonisolated func onViewModelPropertiesListed(_ fileHandle: UInt64, requestID: UInt64, viewModelName: String, properties: [[String: Any]]) {
        let properties = (try? properties.map { dictionary in
            try ViewModelProperty(from: dictionary)
        }) ?? []
        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(properties))
        }
    }

    /// Called when view model enums are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with enum dictionaries that are parsed into `ViewModelEnum` instances.
    nonisolated func onViewModelEnumsListed(_ fileHandle: UInt64, requestID: UInt64, enums: [[String: Any]]) {
        let enums = (try? enums.map { dictionary in
            try ViewModelEnum(from: dictionary)
        }) ?? []

        Task { @MainActor in
            guard let continuation = continuations.removeValue(forKey: requestID) else { return }
            try continuation.resume(with: .success(enums))
        }
    }

    /// Deletes a file via the command queue.
    ///
    /// The continuation is resumed when `onFileDeleted` is called.
    ///
    /// - Parameter file: The file handle to delete
    /// - Returns: The file handle that was deleted
    @MainActor
    func deleteFile(_ file: File.FileHandle) async throws -> File.FileHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = AnyContinuation(continuation)
            commandQueue.deleteFile(file, requestID: requestID)
        }
    }

    /// Deletes a file listener via the command queue.
    ///
    /// - Parameter file: The file handle whose listener should be removed
    @MainActor
    func deleteFileListener(_ file: File.FileHandle) {
        dependencies.commandQueue.deleteFileListener(file)
    }
}

extension FileService {
    /// Container for all dependencies required by the file service.
    struct Dependencies {
        /// The command queue used to send file-related commands to the C++ runtime.
        /// The service registers itself as a `FileListener` observer when calling command
        /// queue methods. All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
    }
}
