//
//  WorkerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
import UIKit
@testable import RiveRuntime

class WorkerTests: XCTestCase {
    #if RIVE_CANVAS
    func test_configuration_defaultsToImmediateRendering() {
        XCTAssertFalse(Worker.Configuration().enableGPUCanvas)
    }

    @MainActor
    func test_configuration_selectsRenderContext() async throws {
        let defaultDevice = await MetalDevice.shared.defaultDevice()
        let device = try XCTUnwrap(defaultDevice?.value)
        let defaultWorker = Worker(device: device)
        let immediateWorker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: false)
        )
        let deferredWorker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )

        XCTAssertTrue(
            defaultWorker.dependencies.workerService.dependencies.renderingMode
                .renderContext
                is RiveUIRenderContext
        )
        XCTAssertTrue(
            immediateWorker.dependencies.workerService.dependencies.renderingMode
                .renderContext
                is RiveUIRenderContext
        )
        XCTAssertTrue(
            deferredWorker.dependencies.workerService.dependencies.renderingMode
                .renderContext
                is _RiveUIDeferredRenderContext
        )
    }

    @MainActor
    func test_makeRenderer_returnsDeferredRenderer() async throws {
        let defaultDevice = await MetalDevice.shared.defaultDevice()
        let device = try XCTUnwrap(defaultDevice?.value)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )

        XCTAssertTrue(worker.makeRenderer() is _RiveUIDeferredRenderer)
    }

    #endif

    @MainActor
    func test_makeRenderer_returnsImmediateRenderer() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let worker = Worker(
            dependencies: .init(workerService: workerService)
        )

        XCTAssertTrue(worker.makeRenderer() is RiveUIRenderer)
    }

    @MainActor
    func test_workerStartsServerOnInitAndDisconnectsQueueOnDeinit() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        
        let serveUntilDisconnectExpectation = expectation(description: "serveUntilDisconnect() should be called when Worker is initialized")
        
        mockCommandServer.stubServeUntilDisconnect {
            serveUntilDisconnectExpectation.fulfill()
        }

        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        
        var worker: Worker? = Worker(
            dependencies: .init(
                workerService: workerService
            )
        )
        _ = worker

        await fulfillment(of: [serveUntilDisconnectExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockCommandServer.serveUntilDisconnectCalls.count, 1, "serveUntilDisconnect() should be called when Worker is initialized")
        
        let disconnectExpectation = expectation(description: "disconnect() should be called when Worker is deinitialized")
        
        mockCommandQueue.stubDisconnect {
            disconnectExpectation.fulfill()
        }
        
        worker = nil
        
        await fulfillment(of: [disconnectExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockCommandQueue.disconnectCalls.count, 1, "disconnect() should be called when Worker is deinitialized")
    }

    @MainActor
    func test_decodeFont_withUIFont_usesUIFontCommandQueueOverload() async throws {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let worker = Worker(dependencies: .init(workerService: workerService))
        let expectedHandle: UInt64 = 42

        let nativeFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        mockCommandQueue.stubDecodeUIFont { font, listener, requestID in
            XCTAssertTrue(font === nativeFont)
            listener.onFontDecoded(expectedHandle, requestID: requestID)
            return expectedHandle
        }

        let font = try await worker.decodeFont(from: nativeFont)

        XCTAssertEqual(font.handle, expectedHandle)
        XCTAssertEqual(mockCommandQueue.decodeFontCalls.count, 0)
        XCTAssertEqual(mockCommandQueue.decodeUIFontCalls.count, 1)
    }

    @MainActor
    func test_decodeFont_withUIFont_succeedsWithRealWorker() async throws {
        let worker = try await Worker()

        let nativeFont = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let font = try await worker.decodeFont(from: nativeFont)
        XCTAssertNotEqual(font.handle, 0)
    }

    @MainActor
    func test_setAndRemoveImage_callsCommandQueueWithCorrectArguments() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)
        
        let mockRenderImageService = ImageService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let renderImageDependencies = Image.Dependencies(imageService: mockRenderImageService)
        let imageHandle: UInt64 = 123
        let renderImage = Image(handle: imageHandle, dependencies: renderImageDependencies)
        
        let imageName = "testImage"
        
        worker.addGlobalImageAsset(renderImage, name: imageName)
        
        XCTAssertEqual(mockCommandQueue.addGlobalImageAssetCalls.count, 1)
        let addCall = mockCommandQueue.addGlobalImageAssetCalls.first!
        XCTAssertEqual(addCall.name, imageName)
        XCTAssertEqual(addCall.imageHandle, imageHandle)
        XCTAssertEqual(addCall.requestID, 0)
        
        worker.removeGlobalImageAsset(name: imageName)
        
        XCTAssertEqual(mockCommandQueue.removeGlobalImageAssetCalls.count, 1)
        let removeCall = mockCommandQueue.removeGlobalImageAssetCalls.first!
        XCTAssertEqual(removeCall.name, imageName)
        XCTAssertEqual(removeCall.requestID, 1)
    }
    
    @MainActor
    func test_setAndRemoveFont_callsCommandQueueWithCorrectArguments() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)

        let mockFontService = FontService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let fontDependencies = Font.Dependencies(fontService: mockFontService)
        let fontHandle: UInt64 = 456
        let font = Font(handle: fontHandle, dependencies: fontDependencies)
        
        let fontName = "testFont"
        
        worker.addGlobalFontAsset(font, name: fontName)
        
        XCTAssertEqual(mockCommandQueue.addGlobalFontAssetCalls.count, 1)
        let addCall = mockCommandQueue.addGlobalFontAssetCalls.first!
        XCTAssertEqual(addCall.name, fontName)
        XCTAssertEqual(addCall.fontHandle, fontHandle)
        XCTAssertEqual(addCall.requestID, 0)
        
        worker.removeGlobalFontAsset(fontName)
        
        XCTAssertEqual(mockCommandQueue.removeGlobalFontAssetCalls.count, 1)
        let removeCall = mockCommandQueue.removeGlobalFontAssetCalls.first!
        XCTAssertEqual(removeCall.name, fontName)
        XCTAssertEqual(removeCall.requestID, 1)
    }
    
    @MainActor
    func test_setAndRemoveAudio_callsCommandQueueWithCorrectArguments() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)

        let mockAudioService = AudioService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let audioDependencies = Audio.Dependencies(audioService: mockAudioService)
        let audioHandle: UInt64 = 789
        let audio = Audio(handle: audioHandle, dependencies: audioDependencies)
        
        let audioName = "testAudio"
        
        worker.addGlobalAudioAsset(audio, name: audioName)
        
        XCTAssertEqual(mockCommandQueue.addGlobalAudioAssetCalls.count, 1)
        let addCall = mockCommandQueue.addGlobalAudioAssetCalls.first!
        XCTAssertEqual(addCall.name, audioName)
        XCTAssertEqual(addCall.audioHandle, audioHandle)
        XCTAssertEqual(addCall.requestID, 0)
        
        worker.removeGlobalAudioAsset(name: audioName)
        
        XCTAssertEqual(mockCommandQueue.removeGlobalAudioAssetCalls.count, 1)
        let removeCall = mockCommandQueue.removeGlobalAudioAssetCalls.first!
        XCTAssertEqual(removeCall.name, audioName)
        XCTAssertEqual(removeCall.requestID, 1)
    }
}
