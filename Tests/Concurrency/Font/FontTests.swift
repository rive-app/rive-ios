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

        let listenerDeleted = expectation(description: "failed decode listener deleted")
        commandQueue.stubDeleteFont { handle in
            XCTAssertEqual(handle, 42)
            fontService.onFontDeleted(handle, requestID: commandQueue.deleteFontCalls.last!.requestID)
        }
        commandQueue.stubDeleteFontListener { handle in
            XCTAssertEqual(handle, 42)
            listenerDeleted.fulfill()
        }
        let expectation = expectation(description: "decodeFont called with error")
        commandQueue.stubDecodeFont { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onFontError(42, requestID: requestID, message: errorMessage)
            return 42
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

        await fulfillment(of: [listenerDeleted], timeout: 1)
        XCTAssertEqual(commandQueue.deleteFontCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteFontListenerCalls.count, 1)
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

        let listenerDeleted = expectation(description: "failed native font listener deleted")
        commandQueue.stubDeleteFont { handle in
            XCTAssertEqual(handle, 1)
            fontService.onFontDeleted(handle, requestID: commandQueue.deleteFontCalls.last!.requestID)
        }
        commandQueue.stubDeleteFontListener { handle in
            XCTAssertEqual(handle, 1)
            listenerDeleted.fulfill()
        }

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
        await fulfillment(of: [listenerDeleted], timeout: 1)
        XCTAssertEqual(commandQueue.deleteFontCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteFontListenerCalls.count, 1)
    }
    
    // MARK: - Cancellation

    @MainActor
    func test_deleteFont_whenAlreadyCancelled_throwsFontErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = FontService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDeleteFont { handle in
            service.onFontDeleted(handle, requestID: commandQueue.deleteFontCalls.last!.requestID)
        }

        let task = Task { @MainActor in
            try await service.deleteFont(42)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected FontError.cancelled")
        } catch FontError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected FontError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.deleteFontCalls.isEmpty)
    }

    @MainActor
    func test_decodeFont_whenAlreadyCancelled_throwsFontErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = FontService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDecodeFont { _, listener, requestID in
            listener.onFontDecoded(42, requestID: requestID)
            return 42
        }

        let task = Task { @MainActor in
            try await service.decodeFont(from: Data([1, 2, 3]))
        }
        // The task cannot enter the main actor until this test suspends.
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected FontError.cancelled")
        } catch FontError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected FontError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.decodeFontCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteFontCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteFontListenerCalls.isEmpty)
    }

    @MainActor
    func test_decodeFont_whenCancelled_throwsCancelledErrorAndCleansUp() async throws {
        for decodeFails in [false, true] {
            let commandQueue = MockCommandQueue()
            let fontService = FontService(dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            ))
            let enteredContinuation = expectation(description: "decode enqueued")
            commandQueue.stubDecodeFont { _, _, _ in
                enteredContinuation.fulfill()
                return 42
            }
            let deletionEnqueued = expectation(description: "cancelled font deletion enqueued")
            commandQueue.stubDeleteFont { handle in
                XCTAssertEqual(handle, 42)
                deletionEnqueued.fulfill()
            }
            let listenerDeleted = expectation(description: "cancelled font listener deleted")
            commandQueue.stubDeleteFontListener { handle in
                XCTAssertEqual(handle, 42)
                listenerDeleted.fulfill()
            }

            let task = Task { @MainActor in
                try await fontService.decodeFont(from: Data([0, 1, 2, 3]))
            }
            await fulfillment(of: [enteredContinuation], timeout: 1)
            task.cancel()

            do {
                _ = try await task.value
                XCTFail("Expected FontError.cancelled")
            } catch FontError.cancelled {
                // Expected while the native decode is still pending.
            } catch {
                XCTFail("Expected FontError.cancelled, got \(error)")
            }

            await fulfillment(of: [deletionEnqueued], timeout: 1)
            XCTAssertTrue(commandQueue.deleteFontListenerCalls.isEmpty)
            let decodeCall = try XCTUnwrap(commandQueue.decodeFontCalls.first)
            if decodeFails {
                fontService.onFontError(42, requestID: decodeCall.requestID, message: "Late decode failure")
            } else {
                fontService.onFontDecoded(42, requestID: decodeCall.requestID)
            }
            let deleteCall = try XCTUnwrap(commandQueue.deleteFontCalls.first)
            fontService.onFontDeleted(42, requestID: deleteCall.requestID)
            await fulfillment(of: [listenerDeleted], timeout: 1)
            XCTAssertEqual(commandQueue.deleteFontCalls.count, 1)
            XCTAssertEqual(commandQueue.deleteFontListenerCalls.count, 1)
        }
    }

    @MainActor
    func test_decodeFont_withUIFont_whenCancelled_throwsCancelledErrorAndCleansUp() async throws {
        for decodeFails in [false, true] {
            let commandQueue = MockCommandQueue()
            let fontService = FontService(dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            ))
            let enteredContinuation = expectation(description: "decode enqueued")
            commandQueue.stubDecodeUIFont { _, _, _ in
                enteredContinuation.fulfill()
                return 42
            }
            let deletionEnqueued = expectation(description: "cancelled font deletion enqueued")
            commandQueue.stubDeleteFont { handle in
                XCTAssertEqual(handle, 42)
                deletionEnqueued.fulfill()
            }
            let listenerDeleted = expectation(description: "cancelled font listener deleted")
            commandQueue.stubDeleteFontListener { handle in
                XCTAssertEqual(handle, 42)
                listenerDeleted.fulfill()
            }

            let task = Task { @MainActor in
                try await fontService.decodeFont(from: UIFont.systemFont(ofSize: 16))
            }
            await fulfillment(of: [enteredContinuation], timeout: 1)
            task.cancel()

            do {
                _ = try await task.value
                XCTFail("Expected FontError.cancelled")
            } catch FontError.cancelled {
                // Expected while the native decode is still pending.
            } catch {
                XCTFail("Expected FontError.cancelled, got \(error)")
            }

            await fulfillment(of: [deletionEnqueued], timeout: 1)
            XCTAssertTrue(commandQueue.deleteFontListenerCalls.isEmpty)
            let decodeCall = try XCTUnwrap(commandQueue.decodeUIFontCalls.first)
            if decodeFails {
                fontService.onFontError(42, requestID: decodeCall.requestID, message: "Late decode failure")
            } else {
                fontService.onFontDecoded(42, requestID: decodeCall.requestID)
            }
            let deleteCall = try XCTUnwrap(commandQueue.deleteFontCalls.first)
            fontService.onFontDeleted(42, requestID: deleteCall.requestID)
            await fulfillment(of: [listenerDeleted], timeout: 1)
            XCTAssertEqual(commandQueue.deleteFontCalls.count, 1)
            XCTAssertEqual(commandQueue.deleteFontListenerCalls.count, 1)
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

    // MARK: - Allocation errors

    @MainActor
    func test_decodeFont_whenNoHandleIsCreated_doesNotDeleteHandle() async {
        let commandQueue = MockCommandQueue()
        var service: FontService? = FontService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        weak var releasedService = service
        commandQueue.stubDecodeFont { _, listener, requestID in
            listener.onFontError(0, requestID: requestID, message: "Allocation failed")
            return 0
        }
        do {
            _ = try await service!.decodeFont(from: Data())
            XCTFail("Expected FontError.failedDecoding")
        } catch FontError.failedDecoding {
        } catch {
            XCTFail("Expected FontError.failedDecoding, got \(error)")
        }
        commandQueue.releaseAssetListeners()
        service = nil

        // Deletion runs in a scheduled MainActor task, but that task strongly
        // captures the service when it is created, before its body runs.
        // After releasing the mock's and test's references, a pending cleanup
        // task would keep releasedService non-nil. Handle 0 must skip creating
        // that task, so this checks ownership without waiting for deletion.
        // The call records also catch deletion if the task has already run.
        XCTAssertNil(releasedService)
        XCTAssertTrue(commandQueue.deleteFontCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteFontListenerCalls.isEmpty)
    }

    @MainActor
    func test_decodeFont_whenCopyThrowsBadAlloc_throwsError() async throws {
        try await assertCopyError(.badAlloc)
    }

    @MainActor
    func test_decodeFont_whenCopyThrowsLengthError_throwsError() async throws {
        try await assertCopyError(.lengthError)
    }

    @MainActor
    func test_decodeFont_withValidData_succeeds() async throws {
        let worker = try await Worker()
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: "Inter-45562", withExtension: "ttf"
        ))
        let validData = try Data(contentsOf: url)
        let asset = try await worker.decodeFont(from: validData)
        XCTAssertNotEqual(asset.handle, 0)
    }

    @MainActor
    private func assertCopyError(_ failure: AssetCopyFailure) async throws {
        let copier = TestAssetDataCopier(failure: failure)
        let worker = try await Worker(assetDataCopier: copier)
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: "Inter-45562", withExtension: "ttf"
        ))
        let validData = try Data(contentsOf: url)
        let finished = expectation(description: "Swift receives copy error")
        let task = Task { @MainActor in
            defer { finished.fulfill() }
            do {
                _ = try await worker.decodeFont(from: validData)
                XCTFail("Expected FontError.failedDecoding")
            } catch FontError.failedDecoding {
            } catch {
                XCTFail("Expected FontError.failedDecoding, got \(error)")
            }
        }
        await fulfillment(of: [finished], timeout: 1)
        task.cancel()
    }

}
