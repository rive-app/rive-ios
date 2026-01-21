//
//  RenderImageTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class ImageTests: XCTestCase {
    
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue))
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
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue))
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
    
    @MainActor
    func test_deinit_callsDeleteImage() async throws {
        let commandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: commandQueue))
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
        commandQueue.stubDeleteImage { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
        }
        
        renderImage = nil
        
        await fulfillment(of: [deleteExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteImageCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteImageCalls.first?.renderImageHandle, 100)
    }
}

