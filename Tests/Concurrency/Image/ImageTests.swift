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

        let listenerDeleted = expectation(description: "failed decode listener deleted")
        commandQueue.stubDeleteImage { handle, _ in
            XCTAssertEqual(handle, 42)
            imageService.onRenderImageDeleted(handle, requestID: commandQueue.deleteImageCalls.last!.requestID)
        }
        commandQueue.stubDeleteImageListener { handle in
            XCTAssertEqual(handle, 42)
            listenerDeleted.fulfill()
        }
        let expectation = expectation(description: "decodeImage called with error")
        commandQueue.stubDecodeImage { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onRenderImageError(42, requestID: requestID, message: errorMessage)
            return 42
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

        await fulfillment(of: [listenerDeleted], timeout: 1)
        XCTAssertEqual(commandQueue.deleteImageCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteImageListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeImageCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeImageCalls.first?.data, testData)
    }

    // MARK: - Cancellation

    @MainActor
    func test_deleteImage_whenAlreadyCancelled_throwsImageErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = ImageService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDeleteImage { handle, _ in
            service.onRenderImageDeleted(handle, requestID: commandQueue.deleteImageCalls.last!.requestID)
        }

        let task = Task { @MainActor in
            try await service.deleteImage(42)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected ImageError.cancelled")
        } catch ImageError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected ImageError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.deleteImageCalls.isEmpty)
    }

    @MainActor
    func test_decodeImage_whenAlreadyCancelled_throwsImageErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = ImageService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDecodeImage { _, listener, requestID in
            listener.onRenderImageDecoded(42, requestID: requestID)
            return 42
        }

        let task = Task { @MainActor in
            try await service.decodeImage(from: Data([1, 2, 3]))
        }
        // The task cannot enter the main actor until this test suspends.
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected ImageError.cancelled")
        } catch ImageError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected ImageError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.decodeImageCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteImageCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteImageListenerCalls.isEmpty)
    }

    @MainActor
    func test_decodeImage_whenCancelled_throwsCancelledErrorAndCleansUp() async throws {
        for decodeFails in [false, true] {
            let commandQueue = MockCommandQueue()
            let imageService = ImageService(dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            ))
            let enteredContinuation = expectation(description: "decode enqueued")
            commandQueue.stubDecodeImage { _, _, _ in
                enteredContinuation.fulfill()
                return 42
            }
            let deletionEnqueued = expectation(description: "cancelled image deletion enqueued")
            commandQueue.stubDeleteImage { handle, _ in
                XCTAssertEqual(handle, 42)
                deletionEnqueued.fulfill()
            }
            let listenerDeleted = expectation(description: "cancelled image listener deleted")
            commandQueue.stubDeleteImageListener { handle in
                XCTAssertEqual(handle, 42)
                listenerDeleted.fulfill()
            }

            let task = Task { @MainActor in
                try await imageService.decodeImage(from: Data([0, 1, 2, 3]))
            }
            await fulfillment(of: [enteredContinuation], timeout: 1)
            task.cancel()

            do {
                _ = try await task.value
                XCTFail("Expected ImageError.cancelled")
            } catch ImageError.cancelled {
                // Expected while the native decode is still pending.
            } catch {
                XCTFail("Expected ImageError.cancelled, got \(error)")
            }

            await fulfillment(of: [deletionEnqueued], timeout: 1)
            XCTAssertTrue(commandQueue.deleteImageListenerCalls.isEmpty)
            let decodeCall = try XCTUnwrap(commandQueue.decodeImageCalls.first)
            if decodeFails {
                imageService.onRenderImageError(42, requestID: decodeCall.requestID, message: "Late decode failure")
            } else {
                imageService.onRenderImageDecoded(42, requestID: decodeCall.requestID)
            }
            let deleteCall = try XCTUnwrap(commandQueue.deleteImageCalls.first)
            imageService.onRenderImageDeleted(42, requestID: deleteCall.requestID)
            await fulfillment(of: [listenerDeleted], timeout: 1)
            XCTAssertEqual(commandQueue.deleteImageCalls.count, 1)
            XCTAssertEqual(commandQueue.deleteImageListenerCalls.count, 1)
        }
    }

    @MainActor
    func test_deleteImage_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDeleteImage { handle, _ in
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
        commandQueue.stubDeleteImage { handle, requestID in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
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

