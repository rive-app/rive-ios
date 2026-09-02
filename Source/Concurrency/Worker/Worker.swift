//
//  Worker.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import Combine
#if canImport(UIKit) || RIVE_MAC_CATALYST
import UIKit
#else
import AppKit
#endif

/// A worker that manages a background instance of Rive for processing data and rendering graphics.
///
/// Each worker spawns a new background instance of Rive capable of processing data and rendering
/// Rive graphics. Workers enable multithreading by allowing multiple independent Rive instances
/// to operate concurrently.
///
/// A worker owns one command queue, command server, and render context. Handles and render
/// resources are scoped to that worker and cannot be exchanged with another worker.
///
/// Workers also manage global assets (images, fonts, and audio) that can be shared across
/// multiple Rive files and artboards loaded by that worker. These assets are registered by name
/// and can be referenced by those files during rendering.
public final class Worker {
    /// Options applied when a worker is created. The resulting rendering mode
    /// and context are fixed for the worker's lifetime.
    public struct Configuration: Sendable {
        #if RIVE_CANVAS
        /// Enables GPU Canvas for every file and renderer created by this
        /// worker. Defaults to `false`, and the selection is fixed for the
        /// worker's lifetime.
        public var enableGPUCanvas = false
        #endif

        /// Creates the default worker configuration.
        public init() {}

        #if RIVE_CANVAS
        /// Creates a configuration with an explicit GPU Canvas choice.
        ///
        /// - Parameter enableGPUCanvas: Whether the worker enables GPU Canvas.
        public init(enableGPUCanvas: Bool) {
            self.enableGPUCanvas = enableGPUCanvas
        }
        #endif
    }

    /// The rendering strategy and concrete context selected for a worker.
    enum RenderingMode {
        case immediate(RiveUIRenderContext)

        #if RIVE_CANVAS
        case deferred(_RiveUIDeferredRenderContext)
        #endif

        var renderContext: any _RiveUIRenderContextProtocol {
            switch self {
            case .immediate(let renderContext):
                renderContext
            #if RIVE_CANVAS
            case .deferred(let renderContext):
                renderContext
            #endif
            }
        }
    }

    let dependencies: Dependencies

    @MainActor
    let globalAssetsDidChange = PassthroughSubject<Void, Never>()

    private var images: [String: Image] = [:]
    private var fonts: [String: Font] = [:]
    private var audios: [String: Audio] = [:]

    @MainActor
    private var hasPendingGlobalAssetsDidChange = false

    /// Selects the worker's rendering strategy once, before command processing
    /// or file import begins. The selected context is reused by both the command
    /// server and every renderer created for this worker.
    private static func makeRenderingMode(
        device: any MTLDevice,
        configuration: Configuration
    ) -> RenderingMode {
        #if RIVE_CANVAS
        if configuration.enableGPUCanvas {
            return .deferred(_RiveUIDeferredRenderContext(device: device))
        }
        #endif

        return .immediate(RiveUIRenderContext(device: device))
    }

    /// Creates a per-surface renderer matching the concrete context already
    /// selected for this worker.
    @MainActor
    func makeRenderer() -> any RiveUIRendererProtocol {
        let dependencies = dependencies.workerService.dependencies

        switch dependencies.renderingMode {
        case .immediate(let renderContext):
            return RiveUIRenderer(
                commandQueue: dependencies.commandQueue,
                renderContext: renderContext
            )
        #if RIVE_CANVAS
        case .deferred(let renderContext):
            return _RiveUIDeferredRenderer(
                commandQueue: dependencies.commandQueue,
                renderContext: renderContext
            )
        #endif
        }
    }

    /// Creates a worker with the default configuration and system Metal device.
    @MainActor
    public convenience init() async throws {
        try await self.init(configuration: .init())
    }

    /// Creates a worker with the supplied configuration and system Metal device.
    ///
    /// - Parameter configuration: Options fixed for the worker's lifetime.
    /// - Throws: `WorkerError.missingDevice` when Metal is unavailable.
    @MainActor
    public convenience init(configuration: Configuration) async throws {
        RiveLog.debug(tag: .worker, "[Worker] Initializing worker")
        guard let device = await MetalDevice.shared.defaultDevice() else {
            let error = WorkerError.missingDevice
            RiveLog.error(tag: .worker, error: error, "[Worker] Failed to initialize worker")
            throw error
        }

        // Context construction is isolated to this detached task, then the
        // completed context is transferred once to the worker. Subsequent C++
        // access is serialized by the command-server processing loop.
        let renderingMode = await Task.detached(
            priority: .userInitiated
        ) { () -> UncheckedSendable<RenderingMode> in
            UncheckedSendable(
                value: Worker.makeRenderingMode(
                    device: device.value,
                    configuration: configuration
                )
            )
        }.value

        let commandQueue = CommandQueue()
        let commandServer = CommandServer(
            commandQueue: commandQueue,
            renderContext: renderingMode.value.renderContext
        )

        self.init(
            dependencies: .init(
                workerService: .init(
                    dependencies: .init(
                        commandQueue: commandQueue,
                        commandServer: commandServer,
                        renderingMode: renderingMode.value,
                        messagePumpDriver: commandQueue
                    )
                )
            )
        )
    }

    /// Creates a worker with the default configuration and supplied Metal device.
    /// Textures rendered by this worker must be created by `device`.
    @MainActor
    public convenience init(device: any MTLDevice) {
        self.init(device: device, configuration: .init())
    }

    /// Creates a worker with a supplied Metal device and configuration.
    ///
    /// - Parameters:
    ///   - device: The device used by the worker's render context and all target textures.
    ///   - configuration: Options fixed for the worker's lifetime.
    @MainActor
    public convenience init(
        device: any MTLDevice,
        configuration: Configuration
    ) {
        RiveLog.debug(tag: .worker, "[Worker] Initializing worker with provided Metal device")
        let renderingMode = Worker.makeRenderingMode(
            device: device,
            configuration: configuration
        )
        let commandQueue = CommandQueue()
        let commandServer = CommandServer(
            commandQueue: commandQueue,
            renderContext: renderingMode.renderContext
        )
        self.init(
            dependencies: .init(
                workerService: .init(
                    dependencies: .init(
                        commandQueue: commandQueue,
                        commandServer: commandServer,
                        renderingMode: renderingMode,
                        messagePumpDriver: commandQueue
                    )
                )
            )
        )
        RiveLog.debug(tag: .worker, "[Worker] Initialized worker with provided Metal device")
    }

    @MainActor
    init(dependencies: Dependencies) {
        defer {
            Task { @MainActor in
                self.dependencies.workerService.start()
            }
        }

        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.workerService
        Task { @MainActor in
            service.stop()
        }
    }

    /// Creates an image from the provided image data by decoding it into an `Image` instance
    /// that can be used as a global asset or assigned to view model properties.
    ///
    /// - Parameter data: The image data to decode (e.g., PNG, JPEG, WebP data)
    /// - Returns: A decoded `Image` instance
    /// - Throws: An error if the image data cannot be decoded
    @MainActor
    public func decodeImage(from data: Data) async throws -> Image {
        RiveLog.debug(tag: .worker, "[Worker] Decoding image data (\(data.count) bytes)")
        let image = try await Image(
            data: data,
            dependencies: .init(
                imageService: .init(
                    dependencies: .init(
                        commandQueue: dependencies.workerService.dependencies.commandQueue,
                        messageGate: dependencies.workerService.messageGate
                    )
                )
            )
        )
        RiveLog.debug(tag: .worker, "[Worker] Decoded image")
        return image
    }

    /// Registers an image as a global asset that can be referenced by name.
    ///
    /// Global assets are out-of-band resources that can be shared across multiple Rive files
    /// and artboards. Once registered, the image can be provided dynamically at runtime
    /// to Rive files that are loaded by this worker.
    ///
    /// - Parameters:
    ///   - image: The image to register as a global asset
    ///   - name: The name to associate with the image asset
    @MainActor
    public func addGlobalImageAsset(_ image: Image, name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Adding global image asset '\(name)'")
        dependencies.workerService.set(image: image.handle, name: name)
        images[name] = image
        notifyGlobalAssetsDidChange()
    }

    /// Removes a global image asset by name.
    ///
    /// After removal, the image can no longer be provided dynamically at runtime to Rive files
    /// loaded by this worker. The image instance itself is not deallocated; only its registration
    /// as a global asset is removed.
    ///
    /// - Parameter name: The name of the image asset to remove
    @MainActor
    public func removeGlobalImageAsset(name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Removing global image asset '\(name)'")
        dependencies.workerService.remove(image: name)
        images.removeValue(forKey: name)
        notifyGlobalAssetsDidChange()
    }

    /// Creates a font from the provided font data by decoding it into a `Font` instance
    /// that can be used as a global asset.
    ///
    /// - Parameter data: The font data to decode (e.g., TTF, OTF data)
    /// - Returns: A decoded `Font` instance
    /// - Throws: An error if the font data cannot be decoded
    @MainActor
    public func decodeFont(from data: Data) async throws -> Font {
        RiveLog.debug(tag: .worker, "[Worker] Decoding font data (\(data.count) bytes)")
        let font = try await Font(
            data: data,
            dependencies: makeFontDependencies()
        )
        RiveLog.debug(tag: .worker, "[Worker] Decoded font")
        return font
    }

    #if canImport(UIKit) || RIVE_MAC_CATALYST
    /// Creates a font from a UIKit font.
    ///
    /// - Parameter font: The UIKit font to decode.
    /// - Returns: A font that can be registered as a global asset.
    /// - Throws: `FontError.failedDecoding` if the native font cannot be converted.
    @MainActor
    public func decodeFont(from font: UIFont) async throws -> Font {
        RiveLog.debug(tag: .worker, "[Worker] Decoding UIFont")
        let font = try await Font(
            font: font,
            dependencies: makeFontDependencies()
        )
        RiveLog.debug(tag: .worker, "[Worker] Decoded UIFont")
        return font
    }
    #else
    /// Creates a font from an AppKit font.
    ///
    /// - Parameter font: The AppKit font to decode.
    /// - Returns: A font that can be registered as a global asset.
    /// - Throws: `FontError.failedDecoding` if the native font cannot be converted.
    @MainActor
    public func decodeFont(from font: NSFont) async throws -> Font {
        RiveLog.debug(tag: .worker, "[Worker] Decoding NSFont")
        let font = try await Font(
            font: font,
            dependencies: makeFontDependencies()
        )
        RiveLog.debug(tag: .worker, "[Worker] Decoded NSFont")
        return font
    }
    #endif

    /// Registers a font as a global asset that can be referenced by name.
    ///
    /// Global assets are out-of-band resources that can be shared across multiple Rive files
    /// and artboards. Once registered, the font can be provided dynamically at runtime
    /// to Rive files that are loaded by this worker.
    ///
    /// - Parameters:
    ///   - font: The font to register as a global asset
    ///   - name: The name to associate with the font asset
    @MainActor
    public func addGlobalFontAsset(_ font: Font, name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Adding global font asset '\(name)'")
        dependencies.workerService.set(font: font.handle, name: name)
        fonts[name] = font
        notifyGlobalAssetsDidChange()
    }

    /// Removes a global font asset by name.
    ///
    /// After removal, the font can no longer be provided dynamically at runtime to Rive files
    /// loaded by this worker. The font instance itself is not deallocated; only its registration
    /// as a global asset is removed.
    ///
    /// - Parameter name: The name of the font asset to remove
    @MainActor
    public func removeGlobalFontAsset(_ name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Removing global font asset '\(name)'")
        dependencies.workerService.remove(font: name)
        fonts.removeValue(forKey: name)
        notifyGlobalAssetsDidChange()
    }

    /// Creates an audio source from the provided audio data by decoding it into an `Audio` instance
    /// that can be used as a global asset.
    ///
    /// - Parameter data: The audio data to decode
    /// - Returns: A decoded `Audio` instance
    /// - Throws: An error if the audio data cannot be decoded
    @MainActor
    public func decodeAudio(from data: Data) async throws -> Audio {
        RiveLog.debug(tag: .worker, "[Worker] Decoding audio data (\(data.count) bytes)")
        let audio = try await Audio(
            data: data,
            dependencies: .init(
                audioService: .init(
                    dependencies: .init(
                        commandQueue: dependencies.workerService.dependencies.commandQueue,
                        messageGate: dependencies.workerService.messageGate
                    )
                )
            )
        )
        RiveLog.debug(tag: .worker, "[Worker] Decoded audio")
        return audio
    }

    /// Registers an audio source as a global asset that can be referenced by name.
    ///
    /// Global assets are out-of-band resources that can be shared across multiple Rive files
    /// and artboards. Once registered, the audio can be provided dynamically at runtime
    /// to Rive files that are loaded by this worker.
    ///
    /// - Parameters:
    ///   - audio: The audio source to register as a global asset
    ///   - name: The name to associate with the audio asset
    @MainActor
    public func addGlobalAudioAsset(_ audio: Audio, name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Adding global audio asset '\(name)'")
        dependencies.workerService.set(audio: audio.handle, name: name)
        audios[name] = audio
        notifyGlobalAssetsDidChange()
    }

    /// Removes a global audio asset by name.
    ///
    /// After removal, the audio can no longer be provided dynamically at runtime to Rive files
    /// loaded by this worker. The audio instance itself is not deallocated; only its registration
    /// as a global asset is removed.
    ///
    /// - Parameter name: The name of the audio asset to remove
    @MainActor
    public func removeGlobalAudioAsset(name: String) {
        RiveLog.debug(tag: .worker, "[Worker] Removing global audio asset '\(name)'")
        dependencies.workerService.remove(audio: name)
        audios.removeValue(forKey: name)
        notifyGlobalAssetsDidChange()
    }

    @MainActor
    private func makeFontDependencies() -> Font.Dependencies {
        .init(
            fontService: .init(
                dependencies: .init(
                    commandQueue: dependencies.workerService.dependencies.commandQueue,
                    messageGate: dependencies.workerService.messageGate
                )
            )
        )
    }

    @MainActor
    private func notifyGlobalAssetsDidChange() {
        guard !hasPendingGlobalAssetsDidChange else {
            return
        }

        hasPendingGlobalAssetsDidChange = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.hasPendingGlobalAssetsDidChange = false
            self.globalAssetsDidChange.send()
        }
    }
}

extension Worker {
    /// Container for all dependencies required by a Worker instance.
    struct Dependencies {
        /// Provides worker-level services including command queue/server lifecycle management
        /// and global asset registration. All operations are fire-and-forget (no listener callbacks).
        let workerService: WorkerService
    }
}
