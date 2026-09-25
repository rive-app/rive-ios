//
//  BlobTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class BlobTests: XCTestCase {

    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let blobService = BlobService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Blob.Dependencies(blobService: blobService)

        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let expectedRequestID: UInt64 = 0

        let expectation = expectation(description: "decodeBlob called")
        commandQueue.stubDecodeBlob { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onBlobDecoded(42, requestID: requestID)
            return 42
        }

        let blob = try await Blob(data: testData, dependencies: dependencies)
        XCTAssertEqual(blob.handle, 42)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(commandQueue.decodeBlobCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeBlobCalls.first?.data, testData)
        XCTAssertEqual(commandQueue.decodeBlobCalls.first?.requestID, expectedRequestID)
    }

    @MainActor
    func test_init_whenCommandQueueReportsError_throwsError() async {
        let commandQueue = MockCommandQueue()
        let blobService = BlobService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Blob.Dependencies(blobService: blobService)

        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let errorMessage = "Failed to decode blob"
        let expectedRequestID: UInt64 = 0

        let listenerDeleted = expectation(description: "failed decode listener deleted")
        commandQueue.stubDeleteBlob { handle in
            XCTAssertEqual(handle, 42)
            blobService.onBlobDeleted(handle, requestID: commandQueue.deleteBlobCalls.last!.requestID)
        }
        commandQueue.stubDeleteBlobListener { handle in
            XCTAssertEqual(handle, 42)
            listenerDeleted.fulfill()
        }
        let expectation = expectation(description: "decodeBlob called with error")
        commandQueue.stubDecodeBlob { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onBlobError(42, requestID: requestID, message: errorMessage)
            return 42
        }

        do {
            _ = try await Blob(data: testData, dependencies: dependencies)
            XCTFail("Error should be thrown")
        } catch BlobError.failedDecoding(let message) {
            await fulfillment(of: [expectation], timeout: 1)
            XCTAssertEqual(message, errorMessage)
        } catch {
            await fulfillment(of: [expectation], timeout: 1)
            XCTFail("Expected BlobError.failedDecoding, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [listenerDeleted], timeout: 1)
        XCTAssertEqual(commandQueue.deleteBlobCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteBlobListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeBlobCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeBlobCalls.first?.data, testData)
    }

    // MARK: - Cancellation

    @MainActor
    func test_decodeBlob_whenAlreadyCancelled_throwsBlobErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = BlobService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDecodeBlob { _, listener, requestID in
            listener.onBlobDecoded(42, requestID: requestID)
            return 42
        }

        let task = Task { @MainActor in
            try await service.decodeBlob(from: Data([1, 2, 3]))
        }
        // The task cannot enter the main actor until this test suspends.
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected BlobError.cancelled")
        } catch BlobError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected BlobError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.decodeBlobCalls.isEmpty)
    }

    @MainActor
    func test_deleteBlob_whenAlreadyCancelled_throwsBlobErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = BlobService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDeleteBlob { handle in
            service.onBlobDeleted(handle, requestID: commandQueue.deleteBlobCalls.last!.requestID)
        }

        let task = Task { @MainActor in
            try await service.deleteBlob(42)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected BlobError.cancelled")
        } catch BlobError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected BlobError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.deleteBlobCalls.isEmpty)
    }

    @MainActor
    func test_decodeBlob_whenCancelled_throwsCancelledErrorAndCleansUp() async throws {
        for decodeFails in [false, true] {
            let commandQueue = MockCommandQueue()
            let blobService = BlobService(dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            ))
            let enteredContinuation = expectation(description: "decode enqueued")
            commandQueue.stubDecodeBlob { _, _, _ in
                enteredContinuation.fulfill()
                return 42
            }
            let deletionEnqueued = expectation(description: "cancelled blob deletion enqueued")
            commandQueue.stubDeleteBlob { handle in
                XCTAssertEqual(handle, 42)
                deletionEnqueued.fulfill()
            }
            let listenerDeleted = expectation(description: "cancelled blob listener deleted")
            commandQueue.stubDeleteBlobListener { handle in
                XCTAssertEqual(handle, 42)
                listenerDeleted.fulfill()
            }

            let task = Task { @MainActor in
                try await blobService.decodeBlob(from: Data([0, 1, 2, 3]))
            }
            await fulfillment(of: [enteredContinuation], timeout: 1)
            task.cancel()

            do {
                _ = try await task.value
                XCTFail("Expected BlobError.cancelled")
            } catch BlobError.cancelled {
                // Expected while the native decode is still pending.
            } catch {
                XCTFail("Expected BlobError.cancelled, got \(error)")
            }

            await fulfillment(of: [deletionEnqueued], timeout: 1)
            XCTAssertTrue(commandQueue.deleteBlobListenerCalls.isEmpty)
            let decodeCall = try XCTUnwrap(commandQueue.decodeBlobCalls.first)
            if decodeFails {
                blobService.onBlobError(42, requestID: decodeCall.requestID, message: "Late decode failure")
            } else {
                blobService.onBlobDecoded(42, requestID: decodeCall.requestID)
            }
            let deleteCall = try XCTUnwrap(commandQueue.deleteBlobCalls.first)
            blobService.onBlobDeleted(42, requestID: deleteCall.requestID)
            await fulfillment(of: [listenerDeleted], timeout: 1)
            XCTAssertEqual(commandQueue.deleteBlobCalls.count, 1)
            XCTAssertEqual(commandQueue.deleteBlobListenerCalls.count, 1)
        }
    }

    @MainActor
    func test_deleteBlob_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let blobService = BlobService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDeleteBlob { handle in
            enteredContinuation.fulfill()
        }

        let task = Task { @MainActor in
            try await blobService.deleteBlob(42)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected BlobError.cancelled to be thrown")
        } catch let error as BlobError {
            guard case .cancelled = error else {
                XCTFail("Expected BlobError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected BlobError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Lifecycle

    @MainActor
    func test_deinit_callsDeleteBlob() async throws {
        let commandQueue = MockCommandQueue()
        let blobService = BlobService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Blob.Dependencies(blobService: blobService)

        let testData = Data([0x00, 0x01, 0x02, 0x03])

        let decodeExpectation = expectation(description: "decodeBlob called")
        commandQueue.stubDecodeBlob { data, listener, requestID in
            XCTAssertEqual(requestID, 0)
            decodeExpectation.fulfill()
            listener.onBlobDecoded(100, requestID: requestID)
            return 100
        }

        var blob: Blob? = try await Blob(data: testData, dependencies: dependencies)
        _ = blob

        await fulfillment(of: [decodeExpectation], timeout: 1)

        XCTAssertEqual(commandQueue.deleteBlobCalls.count, 0)

        let deleteExpectation = expectation(description: "deleteBlob called")
        let deleteListenerExpectation = expectation(description: "deleteBlobListener called")
        commandQueue.stubDeleteBlob { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
            guard let requestID = commandQueue.deleteBlobCalls.last?.requestID else {
                XCTFail("Missing delete blob request ID")
                return
            }
            blobService.onBlobDeleted(handle, requestID: requestID)
        }
        commandQueue.stubDeleteBlobListener { handle in
            XCTAssertEqual(handle, 100)
            deleteListenerExpectation.fulfill()
        }

        blob = nil

        await fulfillment(of: [deleteExpectation, deleteListenerExpectation], timeout: 1)

        XCTAssertEqual(commandQueue.deleteBlobCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteBlobListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteBlobCalls.first?.blobHandle, 100)
        XCTAssertEqual(commandQueue.deleteBlobListenerCalls.first?.blobHandle, 100)
    }

    @MainActor
    func test_decodeBlob_withEmptyData_succeeds() async throws {
        let worker = try await Worker()
        let finished = expectation(description: "Empty blob decoded")
        let task = Task { @MainActor in
            defer { finished.fulfill() }
            do {
                let blob = try await worker.decodeBlob(from: Data())
                XCTAssertNotEqual(blob.handle, 0)
            } catch {
                XCTFail("Empty blob decoding failed: \(error)")
            }
        }
        await fulfillment(of: [finished], timeout: 1)
        task.cancel()
    }

    // MARK: - Allocation errors

    @MainActor
    func test_decodeBlob_whenNoHandleIsCreated_doesNotDeleteHandle() async {
        let commandQueue = MockCommandQueue()
        var service: BlobService? = BlobService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        weak var releasedService = service
        commandQueue.stubDecodeBlob { _, listener, requestID in
            listener.onBlobError(0, requestID: requestID, message: "Allocation failed")
            return 0
        }
        do {
            _ = try await service!.decodeBlob(from: Data())
            XCTFail("Expected BlobError.failedDecoding")
        } catch BlobError.failedDecoding {
        } catch {
            XCTFail("Expected BlobError.failedDecoding, got \(error)")
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
        XCTAssertTrue(commandQueue.deleteBlobCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteBlobListenerCalls.isEmpty)
    }

    @MainActor
    func test_decodeBlob_whenCopyThrowsBadAlloc_throwsError() async throws {
        try await assertCopyError(.badAlloc)
    }

    @MainActor
    func test_decodeBlob_whenCopyThrowsLengthError_throwsError() async throws {
        try await assertCopyError(.lengthError)
    }

    @MainActor
    func test_decodeBlob_withValidData_succeeds() async throws {
        let worker = try await Worker()
        let validData = Data([0x00, 0x01, 0x02, 0x03])
        let asset = try await worker.decodeBlob(from: validData)
        XCTAssertNotEqual(asset.handle, 0)
    }

    @MainActor
    private func assertCopyError(_ failure: AssetCopyFailure) async throws {
        let copier = TestAssetDataCopier(failure: failure)
        let worker = try await Worker(assetDataCopier: copier)
        let validData = Data([0x00, 0x01, 0x02, 0x03])
        let finished = expectation(description: "Swift receives copy error")
        let task = Task { @MainActor in
            defer { finished.fulfill() }
            do {
                _ = try await worker.decodeBlob(from: validData)
                XCTFail("Expected BlobError.failedDecoding")
            } catch BlobError.failedDecoding {
            } catch {
                XCTFail("Expected BlobError.failedDecoding, got \(error)")
            }
        }
        await fulfillment(of: [finished], timeout: 1)
        task.cancel()
    }

}
