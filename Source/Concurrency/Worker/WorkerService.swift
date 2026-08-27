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
/// Schedules command-server processing, coordinates queue shutdown, and manages global assets
/// (images, fonts, audio) shared by files in one worker. All asset operations are fire-and-forget
/// (no listener callbacks). Command queue operations are isolated to the main actor.
@MainActor
final class WorkerService {
    let dependencies: Dependencies
    lazy var messageGate = CommandQueueMessageGate(
        driver: dependencies.messagePumpDriver
    )

    @MainActor
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Schedules command-server processing for the existing queue.
    ///
    /// The server dispatches its blocking loop internally and runs until the queue disconnects.
    @MainActor
    func start() {
        RiveLog.debug(tag: .worker, "[Worker] Starting worker")
        dependencies.commandServer.serveUntilDisconnect()
    }

    /// Begins asynchronous worker shutdown.
    ///
    /// Stops message pumping and enqueues the queue's disconnect command. The server exits its
    /// background loop afterward and then ends the render context's processing session.
    @MainActor
    func stop() {
        RiveLog.debug(tag: .worker, "[Worker] Stopping worker")
        messageGate.stop()
        dependencies.commandQueue.disconnect()
    }

    /// Registers an image as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(image: Image.ImageHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Registering global image asset '\(name)'")
        dependencies.commandQueue.addGlobalImageAsset(name, imageHandle: image, requestID: requestID)
    }

    /// Removes a global image asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(image: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Removing global image asset '\(image)'")
        dependencies.commandQueue.removeGlobalImageAsset(image, requestID: requestID)
    }

    /// Registers a font as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(font: Font.FontHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Registering global font asset '\(name)'")
        dependencies.commandQueue.addGlobalFontAsset(name, fontHandle: font, requestID: requestID)
    }

    /// Removes a global font asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(font: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Removing global font asset '\(font)'")
        dependencies.commandQueue.removeGlobalFontAsset(font, requestID: requestID)
    }

    /// Registers an audio source as a global asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func set(audio: Audio.AudioHandle, name: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Registering global audio asset '\(name)'")
        dependencies.commandQueue.addGlobalAudioAsset(name, audioHandle: audio, requestID: requestID)
    }

    /// Removes a global audio asset.
    ///
    /// Delegates to the command queue. No listener callback is invoked for this operation.
    @MainActor
    func remove(audio: String) {
        let requestID = dependencies.commandQueue.nextRequestID
        RiveLog.debug(tag: .worker, "[Worker] Removing global audio asset '\(audio)'")
        dependencies.commandQueue.removeGlobalAudioAsset(audio, requestID: requestID)
    }
}

extension WorkerService {
    /// Container for all dependencies required by the worker service.
    struct Dependencies {
        /// The command queue used to send commands to the C++ runtime.
        /// All operations must be performed on the main actor.
        let commandQueue: CommandQueueProtocol
        /// The command server that processes commands from the command queue on a background thread.
        let commandServer: CommandServerProtocol
        /// The selected per-worker rendering mode. Its context is supplied to
        /// the command server, and the same mode selects each renderer.
        let renderingMode: Worker.RenderingMode
        /// Internal queue lifecycle driver used by the message gate.
        let messagePumpDriver: any _CommandQueueMessagePumpDriver

        init(
            commandQueue: CommandQueueProtocol,
            commandServer: CommandServerProtocol,
            renderingMode: Worker.RenderingMode,
            messagePumpDriver: any _CommandQueueMessagePumpDriver
        ) {
            self.commandQueue = commandQueue
            self.commandServer = commandServer
            self.renderingMode = renderingMode
            self.messagePumpDriver = messagePumpDriver
        }
    }
}
