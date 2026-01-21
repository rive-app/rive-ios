//
//  WorkerService.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A service class that manages worker lifecycle and global asset registration.
///
/// Handles starting/stopping the command queue and command server, and manages global assets
/// (images, fonts, audio) that can be shared across multiple Rive files. All operations are
/// fire-and-forget (no listener callbacks). All command queue operations must be performed on
/// the main thread (either marked `@MainActor` or dispatched to the main queue).
class WorkerService {
    let dependencies: Dependencies

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Starts the command queue and command server.
    ///
    /// The command server runs until disconnected, processing commands from the command queue
    /// on a background thread.
    @MainActor
    func start() {
        dependencies.commandQueue.start()
        dependencies.commandServer.serveUntilDisconnect()
    }

    /// Stops the command queue and command server.
    ///
    /// Disconnects the command server and stops the command queue, shutting down the worker.
    @MainActor
    func stop() {
        dependencies.commandQueue.disconnect()
        dependencies.commandQueue.stop()
    }

    /// Registers an image as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(image: Image.ImageHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.addGlobalImageAsset(name, imageHandle: image, requestID: requestID)
    }

    /// Removes a global image asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(image: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.removeGlobalImageAsset(image, requestID: requestID)
    }

    /// Registers a font as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(font: Font.FontHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.addGlobalFontAsset(name, fontHandle: font, requestID: requestID)
    }

    /// Removes a global font asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(font: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.removeGlobalFontAsset(font, requestID: requestID)
    }

    /// Registers an audio source as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(audio: Audio.AudioHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.addGlobalAudioAsset(name, audioHandle: audio, requestID: requestID)
    }

    /// Removes a global audio asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(audio: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        dependencies.commandQueue.removeGlobalAudioAsset(audio, requestID: requestID)
    }
}

extension WorkerService {
    /// Container for all dependencies required by the worker service.
    struct Dependencies {
        /// The command queue used to send commands to the C++ runtime.
        /// All operations must be performed on the main thread.
        let commandQueue: CommandQueueProtocol
        /// The command server that processes commands from the command queue on a background thread.
        let commandServer: CommandServerProtocol
        /// The render context used for rendering operations.
        let renderContext: RiveRenderContext
    }
}
