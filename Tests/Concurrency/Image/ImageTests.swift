//
//  RenderImageTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class ImageTests: XCTestCase {
    
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Image.Dependencies(imageService: imageService)
        
        let testData = Data([0x89, 0x50, 0x4E, 0x47])
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "decodeImage called")
        commandQueue.stubDecodeImage { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onRenderImageDecoded(42, requestID: requestID)
            return 42
        }
        
        let renderImage = try await Image(data: testData, dependencies: dependencies)
        XCTAssertEqual(renderImage.handle, 42)

        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.decodeImageCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeImageCalls.first?.data, testData)
        XCTAssertEqual(commandQueue.decodeImageCalls.first?.requestID, expectedRequestID)
    }
    
    @MainActor
    func test_init_withInvalidData_throwsError() async {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Image.Dependencies(imageService: imageService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let errorMessage = "Failed to decode image"
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "decodeImage called with error")
        commandQueue.stubDecodeImage { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onRenderImageError(0, requestID: requestID, message: errorMessage)
            return 0
        }
        
        do {
            _ = try await Image(data: testData, dependencies: dependencies)
            XCTFail("Error should be thrown")
        } catch ImageError.failedDecoding(let message) {
            await fulfillment(of: [expectation], timeout: 1)
            XCTAssertEqual(message, errorMessage)
        } catch {
            await fulfillment(of: [expectation], timeout: 1)
            XCTFail("Expected ImageError.failedDecoding, got \(type(of: error)): \(error)")
        }
        
        XCTAssertEqual(commandQueue.decodeImageCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeImageCalls.first?.data, testData)
    }
    
    // MARK: - Cancellation

    @MainActor
    func test_decodeImage_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let testData = Data([0x89, 0x50, 0x4E, 0x47])

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDecodeImage { data, listener, requestID in
            enteredContinuation.fulfill()
            return 0
        }

        let task = Task { @MainActor in
            try await imageService.decodeImage(from: testData)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected ImageError.cancelled to be thrown")
        } catch let error as ImageError {
            guard case .cancelled = error else {
                XCTFail("Expected ImageError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected ImageError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_deleteImage_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDeleteImage { handle in
            enteredContinuation.fulfill()
        }

        let task = Task { @MainActor in
            try await imageService.deleteImage(42)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected ImageError.cancelled to be thrown")
        } catch let error as ImageError {
            guard case .cancelled = error else {
                XCTFail("Expected ImageError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected ImageError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Lifecycle

    @MainActor
    func test_deinit_callsDeleteImage() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Image.Dependencies(imageService: imageService)
        
        let testData = Data([0x89, 0x50, 0x4E, 0x47])
        
        let decodeExpectation = expectation(description: "decodeImage called")
        commandQueue.stubDecodeImage { data, listener, requestID in
            XCTAssertEqual(requestID, 0)
            decodeExpectation.fulfill()
            listener.onRenderImageDecoded(100, requestID: requestID)
            return 100
        }
        
        var renderImage: Image? = try await Image(data: testData, dependencies: dependencies)
        _ = renderImage

        await fulfillment(of: [decodeExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteImageCalls.count, 0)
        
        let deleteExpectation = expectation(description: "deleteImage called")
        let deleteListenerExpectation = expectation(description: "deleteImageListener called")
        commandQueue.stubDeleteImage { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
            guard let requestID = commandQueue.deleteImageCalls.last?.requestID else {
                XCTFail("Missing delete image request ID")
                return
            }
            imageService.onRenderImageDeleted(handle, requestID: requestID)
        }
        commandQueue.stubDeleteImageListener { handle in
            XCTAssertEqual(handle, 100)
            deleteListenerExpectation.fulfill()
        }
        
        renderImage = nil
        
        await fulfillment(of: [deleteExpectation, deleteListenerExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteImageCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteImageListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteImageCalls.first?.renderImageHandle, 100)
        XCTAssertEqual(commandQueue.deleteImageListenerCalls.first?.renderImageHandle, 100)
    }
}

