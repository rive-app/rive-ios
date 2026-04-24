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
final class FileService: NSObject, FileListener {
    /// The dependencies required for file service operations.
    private let dependencies: Dependencies

    /// A dictionary mapping request IDs to their corresponding continuations.
    ///
    /// Continuations are stored when command queue functions are called and resumed when
    /// listener callbacks are invoked. Access must be on the main thread.
    private struct PendingRequest {
        let continuation: AnyContinuation
        let mapError: (String) -> Error
    }

    private var continuations: [UInt64: PendingRequest] = [:]
    
    private static func context(_ file: File.FileHandle) -> String {
        "[File (\(file))]"
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
    }

    private func beginImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.processMessagesImmediately(requestID: requestID)
    }

    private func finishImmediateRequest(_ requestID: UInt64) {
        dependencies.messageGate.callbackProcessed(requestID: requestID)
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
        RiveLog.debug(tag: .file, "[File] Loading file (\(data.count) bytes)")
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
            commandQueue.loadFile(data, observer: self, requestID: requestID)
        }
    }

    /// Instantiates an artboard from a loaded file asynchronously.
    ///
    /// The continuation is resumed when `onArtboardInstantiated` is called, or fails
    /// via `onFileError` if the server could not instantiate the artboard.
    ///
    /// - Parameters:
    ///   - name: The name of the artboard to instantiate. If `nil`, the default artboard is instantiated.
    ///   - fileHandle: The file handle for the loaded file.
    ///   - observer: The observer to register for subsequent artboard-level callbacks.
    /// - Returns: The handle of the instantiated artboard.
    /// - Throws: `FileError.invalidArtboard` if the server reports an error.
    @MainActor
    func instantiateArtboard(name: String?, fileHandle: File.FileHandle, observer: ArtboardListener) async throws -> Artboard.ArtboardHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidArtboard)
            beginImmediateRequest(requestID)
            if let name {
                _ = commandQueue.createArtboardNamed(name, fromFile: fileHandle, observer: observer, requestID: requestID)
            } else {
                _ = commandQueue.createDefaultArtboard(fromFile: fileHandle, observer: observer, requestID: requestID)
            }
        }
    }

    /// Instantiates a view model instance from a loaded file asynchronously.
    ///
    /// The continuation is resumed when `onViewModelInstanceInstantiated` is called, or fails
    /// via `onFileError` if the server could not instantiate the view model instance.
    ///
    /// - Parameters:
    ///   - source: The source specifying which view model instance to create.
    ///   - fileHandle: The file handle for the loaded file.
    ///   - observer: The observer to register for subsequent view-model-instance-level callbacks.
    /// - Returns: The handle of the instantiated view model instance.
    /// - Throws: `FileError.invalidViewModelInstance` if the server reports an error.
    @MainActor
    func instantiateViewModelInstance(source: ViewModelInstanceSource, fileHandle: File.FileHandle, observer: ViewModelInstanceListener) async throws -> ViewModelInstance.ViewModelInstanceHandle {
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidViewModelInstance)
            beginImmediateRequest(requestID)
            switch source {
            case .blank(let viewModelSource):
                switch viewModelSource {
                case .artboardDefault(let artboard):
                    _ = commandQueue.createBlankViewModelInstance(forArtboard: artboard.artboardHandle, fromFile: fileHandle, observer: observer, requestID: requestID)
                case .name(let viewModelName):
                    _ = commandQueue.createBlankViewModelInstanceNamed(viewModelName, fromFile: fileHandle, observer: observer, requestID: requestID)
                }
            case .viewModelDefault(let viewModelSource):
                switch viewModelSource {
                case .artboardDefault(let artboard):
                    _ = commandQueue.createDefaultViewModelInstance(forArtboard: artboard.artboardHandle, fromFile: fileHandle, observer: observer, requestID: requestID)
                case .name(let viewModelName):
                    _ = commandQueue.createDefaultViewModelInstanceNamed(viewModelName, fromFile: fileHandle, observer: observer, requestID: requestID)
                }
            case .name(let instanceName, let viewModelSource):
                switch viewModelSource {
                case .artboardDefault(let artboard):
                    _ = commandQueue.createViewModelInstanceNamed(instanceName, forArtboard: artboard.artboardHandle, fromFile: fileHandle, observer: observer, requestID: requestID)
                case .name(let viewModelName):
                    _ = commandQueue.createViewModelInstanceNamed(instanceName, viewModelName: viewModelName, fromFile: fileHandle, observer: observer, requestID: requestID)
                }
            }
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
        RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Requesting artboard names")
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
        RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Requesting view model names")
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
        RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Requesting instance names for view model '\(viewModelName)'")
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
        RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Requesting property definitions for view model '\(viewModelName)'")
        let commandQueue = dependencies.commandQueue
        let properties: [ViewModelProperty] = try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
        RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Requesting view model enums")
        let commandQueue = dependencies.commandQueue
        let enums: [ViewModelEnum] = try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(handle)) Loaded file")
            try request.continuation.resume(with: .success(handle))
        }
    }

    /// Called when a file deletion operation completes.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to
    /// resume the continuation associated with the delete request.
    nonisolated func onFileDeleted(_ handle: UInt64, requestID: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(handle)) Deleted file")
            try request.continuation.resume(with: .success(handle))
        }
    }

    /// Called when a file operation encounters an error.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the error type appropriate
    /// for the operation that was attempted.
    ///
    /// - Parameters:
    ///   - fileHandle: The file handle associated with the failed operation
    ///   - requestID: The request ID matching the one used when initiating the operation
    ///   - message: Error message from the C++ runtime
    nonisolated func onFileError(_ fileHandle: UInt64, requestID: UInt64, message: String) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.error(tag: .file, "\(Self.context(fileHandle)) Operation failed: \(message)")
            try request.continuation.resume(with: .failure(request.mapError(message)))
        }
    }

    /// Called when an artboard has been successfully instantiated from a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the new artboard handle.
    nonisolated func onArtboardInstantiated(_ fileHandle: UInt64, requestID: UInt64, artboardHandle: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Instantiated artboard (\(artboardHandle))")
            try request.continuation.resume(with: .success(artboardHandle))
        }
    }

    /// Called when a view model instance has been successfully instantiated from a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to access
    /// continuations dictionary and resume the continuation with the new view model instance handle.
    nonisolated func onViewModelInstanceInstantiated(_ fileHandle: UInt64, requestID: UInt64, viewModelInstanceHandle: UInt64) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Instantiated view model instance (\(viewModelInstanceHandle))")
            try request.continuation.resume(with: .success(viewModelInstanceHandle))
        }
    }

    /// Called when artboard names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the artboard names.
    nonisolated func onArtboardsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Received \(names.count) artboard names")
            try request.continuation.resume(with: .success(names))
        }
    }

    /// Called when view model names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the view model names.
    nonisolated func onViewModelsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Received \(names.count) view model names")
            try request.continuation.resume(with: .success(names))
        }
    }

    /// Called when view model instance names are listed for a file.
    ///
    /// Listener callback invoked by the command server. Dispatches to main actor to resume
    /// the continuation with the instance names.
    nonisolated func onViewModelInstanceNamesListed(_ fileHandle: UInt64, requestID: UInt64, viewModelName: String, names: [String]) {
        Task { @MainActor in
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Received \(names.count) instance names for view model '\(viewModelName)'")
            try request.continuation.resume(with: .success(names))
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
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Received \(properties.count) property definitions for view model '\(viewModelName)'")
            try request.continuation.resume(with: .success(properties))
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
            finishImmediateRequest(requestID)
            guard let request = continuations.removeValue(forKey: requestID) else { return }
            RiveLog.debug(tag: .file, "\(Self.context(fileHandle)) Received \(enums.count) view model enums")
            try request.continuation.resume(with: .success(enums))
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
        RiveLog.debug(tag: .file, "\(Self.context(file)) Deleting file")
        let commandQueue = dependencies.commandQueue
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = commandQueue.nextRequestID
            continuations[requestID] = PendingRequest(continuation: AnyContinuation(continuation), mapError: FileError.invalidFile)
            beginImmediateRequest(requestID)
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
        let messageGate: CommandQueueMessageGate

        init(commandQueue: CommandQueueProtocol, messageGate: CommandQueueMessageGate) {
            self.commandQueue = commandQueue
            self.messageGate = messageGate
        }
    }
}
