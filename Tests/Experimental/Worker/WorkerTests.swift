//
//  WorkerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/11/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class WorkerTests: XCTestCase {
    @MainActor
    func test_worker_startsOnInitAndStopsOnDeinit() async {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        
        let startExpectation = expectation(description: "start() should be called when Worker is initialized")
        let serveUntilDisconnectExpectation = expectation(description: "serveUntilDisconnect() should be called when Worker is initialized")
        
        mockCommandQueue.stubStart {
            startExpectation.fulfill()
        }
        
        mockCommandServer.stubServeUntilDisconnect {
            serveUntilDisconnectExpectation.fulfill()
        }
        
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderContext: RiveRenderContext()
            )
        )
        
        var worker: Worker? = Worker(
            dependencies: .init(
                workerService: workerService
            )
        )
        _ = worker

        await fulfillment(of: [startExpectation, serveUntilDisconnectExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockCommandQueue.startCalls.count, 1, "start() should be called when Worker is initialized")
        
        XCTAssertEqual(mockCommandServer.serveUntilDisconnectCalls.count, 1, "serveUntilDisconnect() should be called when Worker is initialized")
        
        let disconnectExpectation = expectation(description: "disconnect() should be called when Worker is deinitialized")
        let stopExpectation = expectation(description: "stop() should be called when Worker is deinitialized")
        
        mockCommandQueue.stubDisconnect {
            disconnectExpectation.fulfill()
        }
        
        mockCommandQueue.stubStop {
            stopExpectation.fulfill()
        }
        
        worker = nil
        
        await fulfillment(of: [disconnectExpectation, stopExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockCommandQueue.disconnectCalls.count, 1, "disconnect() should be called when Worker is deinitialized")
        
        XCTAssertEqual(mockCommandQueue.stopCalls.count, 1, "stop() should be called when Worker is deinitialized")
    }

    @MainActor
    func test_setAndRemoveImage_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderContext: RiveRenderContext()
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)
        
        let mockRenderImageService = ImageService(dependencies: .init(commandQueue: mockCommandQueue))
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
    func test_setAndRemoveFont_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderContext: RiveRenderContext()
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)

        let mockFontService = FontService(dependencies: .init(commandQueue: mockCommandQueue))
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
    func test_setAndRemoveAudio_callsCommandQueueWithCorrectArguments() {
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderContext: RiveRenderContext()
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)

        let mockAudioService = AudioService(dependencies: .init(commandQueue: mockCommandQueue))
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

