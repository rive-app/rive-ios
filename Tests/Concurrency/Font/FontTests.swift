//
//  FontTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
import UIKit
@testable import RiveRuntime

class FontTests: XCTestCase {
    
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Font.Dependencies(fontService: fontService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "decodeFont called")
        commandQueue.stubDecodeFont { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onFontDecoded(42, requestID: requestID)
            return 42
        }
        
        let font = try await Font(data: testData, dependencies: dependencies)
        XCTAssertEqual(font.handle, 42)

        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.decodeFontCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeFontCalls.first?.data, testData)
        XCTAssertEqual(commandQueue.decodeFontCalls.first?.requestID, expectedRequestID)
    }
    
    @MainActor
    func test_init_withInvalidData_throwsError() async {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Font.Dependencies(fontService: fontService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let errorMessage = "Failed to decode font"
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "decodeFont called with error")
        commandQueue.stubDecodeFont { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onFontError(0, requestID: requestID, message: errorMessage)
            return 0
        }
        
        do {
            _ = try await Font(data: testData, dependencies: dependencies)
            XCTFail("Error should be thrown")
        } catch FontError.failedDecoding(let message) {
            await fulfillment(of: [expectation], timeout: 1)
            XCTAssertEqual(message, errorMessage)
        } catch {
            await fulfillment(of: [expectation], timeout: 1)
            XCTFail("Expected FontError.failedDecoding, got \(type(of: error)): \(error)")
        }
        
        XCTAssertEqual(commandQueue.decodeFontCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeFontCalls.first?.data, testData)
    }

    @MainActor
    func test_init_withUIFont_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Font.Dependencies(fontService: fontService)
        let expectedRequestID: UInt64 = 0
        let expectedHandle: UInt64 = 42

        let expectation = expectation(description: "decode native font called")
        let nativeFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        commandQueue.stubDecodeUIFont { font, listener, requestID in
            XCTAssertTrue(font === nativeFont)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onFontDecoded(expectedHandle, requestID: requestID)
            return expectedHandle
        }
        let font = try await Font(font: nativeFont, dependencies: dependencies)
        let call = try XCTUnwrap(commandQueue.decodeUIFontCalls.first)
        XCTAssertTrue(call.font === nativeFont)
        XCTAssertEqual(call.requestID, expectedRequestID)

        XCTAssertEqual(font.handle, expectedHandle)
        XCTAssertEqual(commandQueue.decodeFontCalls.count, 0)
        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_init_withUIFont_whenDecodingFails_throwsError() async {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Font.Dependencies(fontService: fontService)
        let errorMessage = "Failed to decode native font"

        let nativeFont = UIFont.systemFont(ofSize: 16)
        commandQueue.stubDecodeUIFont { _, listener, requestID in
            listener.onFontError(1, requestID: requestID, message: errorMessage)
            return 1
        }

        do {
            _ = try await Font(font: nativeFont, dependencies: dependencies)
            XCTFail("Error should be thrown")
        } catch FontError.failedDecoding(let message) {
            XCTAssertEqual(message, errorMessage)
        } catch {
            XCTFail("Expected FontError.failedDecoding, got \(type(of: error)): \(error)")
        }
    }
    
    // MARK: - Cancellation

    @MainActor
    func test_decodeFont_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let testData = Data([0x00, 0x01, 0x02, 0x03])

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDecodeFont { data, listener, requestID in
            enteredContinuation.fulfill()
            return 0
        }

        let task = Task { @MainActor in
            try await fontService.decodeFont(from: testData)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected FontError.cancelled to be thrown")
        } catch let error as FontError {
            guard case .cancelled = error else {
                XCTFail("Expected FontError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FontError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_decodeFont_withUIFont_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let enteredContinuation = expectation(description: "entered native font continuation")

        let nativeFont = UIFont.systemFont(ofSize: 16)
        commandQueue.stubDecodeUIFont { _, _, _ in
            enteredContinuation.fulfill()
            return 1
        }

        let task = Task { @MainActor in
            try await fontService.decodeFont(from: nativeFont)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected FontError.cancelled to be thrown")
        } catch let error as FontError {
            guard case .cancelled = error else {
                XCTFail("Expected FontError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FontError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_deleteFont_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDeleteFont { handle in
            enteredContinuation.fulfill()
        }

        let task = Task { @MainActor in
            try await fontService.deleteFont(42)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected FontError.cancelled to be thrown")
        } catch let error as FontError {
            guard case .cancelled = error else {
                XCTFail("Expected FontError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FontError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Lifecycle

    @MainActor
    func test_deinit_callsDeleteFont() async throws {
        let commandQueue = MockCommandQueue()
        let fontService = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Font.Dependencies(fontService: fontService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        
        let decodeExpectation = expectation(description: "decodeFont called")
        commandQueue.stubDecodeFont { data, listener, requestID in
            XCTAssertEqual(requestID, 0)
            decodeExpectation.fulfill()
            listener.onFontDecoded(100, requestID: requestID)
            return 100
        }
        
        var font: Font? = try await Font(data: testData, dependencies: dependencies)
        _ = font

        await fulfillment(of: [decodeExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteFontCalls.count, 0)
        
        let deleteExpectation = expectation(description: "deleteFont called")
        let deleteListenerExpectation = expectation(description: "deleteFontListener called")
        commandQueue.stubDeleteFont { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
            guard let requestID = commandQueue.deleteFontCalls.last?.requestID else {
                XCTFail("Missing delete font request ID")
                return
            }
            fontService.onFontDeleted(handle, requestID: requestID)
        }
        commandQueue.stubDeleteFontListener { handle in
            XCTAssertEqual(handle, 100)
            deleteListenerExpectation.fulfill()
        }
        
        font = nil
        
        await fulfillment(of: [deleteExpectation, deleteListenerExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteFontCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteFontListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteFontCalls.first?.fontHandle, 100)
        XCTAssertEqual(commandQueue.deleteFontListenerCalls.first?.fontHandle, 100)
    }
}
