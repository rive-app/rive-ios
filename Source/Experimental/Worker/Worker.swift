//
//  Worker.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A worker that manages a background instance of Rive for processing data and rendering graphics.
///
/// Each worker spawns a new background instance of Rive capable of processing data and rendering
/// Rive graphics. Workers enable multithreading by allowing multiple independent Rive instances
/// to operate concurrently.
///
/// Workers also manage global assets (images, fonts, and audio) that can be shared across
/// multiple Rive files and artboards. These assets are registered by name and can be referenced
/// by Rive files during rendering.
@_spi(RiveExperimental)
public class Worker {
    let dependencies: Dependencies

    private var images: [String: Image] = [:]
    private var fonts: [String: Font] = [:]
    private var audios: [String: Audio] = [:]
    
    /// Creates a new worker that spawns a new background instance of Rive.
    ///
    /// The worker will automatically start processing when initialized.
    @MainActor
    public convenience init() throws {
        guard let device = MetalDevice.shared.defaultDevice()?.value else {
            throw WorkerError.missingDevice
        }

        self.init(device: device)
    }

    @MainActor
    public convenience init() async throws {
        guard let device = await MetalDevice.shared.defaultDevice()?.value else {
            throw WorkerError.missingDevice
        }
        self.init(device: device)
    }

    @MainActor
    public convenience init(device: any MTLDevice) {
        let renderContext = RiveRenderContext(device: device)
        let commandQueue = CommandQueue()
        let commandServer = CommandServer(commandQueue: commandQueue, renderContext: renderContext)
        self.init(
            dependencies: .init(
                workerService: .init(
                    dependencies: .init(
                        commandQueue: commandQueue,
                        commandServer: commandServer,
                        renderContext: renderContext
                    )
                )
            )
        )
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
        return try await Image(
            data: data,
            dependencies: .init(
                imageService: .init(
                    dependencies: .init(
                        commandQueue: dependencies.workerService.dependencies.commandQueue
                    )
                )
            )
        )
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
        dependencies.workerService.set(image: image.handle, name: name)
        images[name] = image
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
        dependencies.workerService.remove(image: name)
        images.removeValue(forKey: name)
    }

    /// Creates a font from the provided font data by decoding it into a `Font` instance
    /// that can be used as a global asset.
    ///
    /// - Parameter data: The font data to decode (e.g., TTF, OTF data)
    /// - Returns: A decoded `Font` instance
    /// - Throws: An error if the font data cannot be decoded
    @MainActor
    public func decodeFont(from data: Data) async throws -> Font {
        return try await Font(
            data: data,
            dependencies: .init(
                fontService: .init(
                    dependencies: .init(
                        commandQueue: dependencies.workerService.dependencies.commandQueue
                    )
                )
            )
        )
    }

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
        dependencies.workerService.set(font: font.handle, name: name)
        fonts[name] = font
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
        dependencies.workerService.remove(font: name)
        fonts.removeValue(forKey: name)
    }

    /// Creates an audio source from the provided audio data by decoding it into an `Audio` instance
    /// that can be used as a global asset.
    ///
    /// - Parameter data: The audio data to decode
    /// - Returns: A decoded `Audio` instance
    /// - Throws: An error if the audio data cannot be decoded
    @MainActor
    public func decodeAudio(from data: Data) async throws -> Audio {
        return try await Audio(
            data: data,
            dependencies: .init(
                audioService: .init(
                    dependencies: .init(
                        commandQueue: dependencies.workerService.dependencies.commandQueue
                    )
                )
            )
        )
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
        dependencies.workerService.set(audio: audio.handle, name: name)
        audios[name] = audio
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
        dependencies.workerService.remove(audio: name)
        audios.removeValue(forKey: name)
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
