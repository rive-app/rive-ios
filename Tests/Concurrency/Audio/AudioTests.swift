//
//  AudioTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class AudioTests: XCTestCase {
    
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Audio.Dependencies(audioService: audioService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "decodeAudio called")
        commandQueue.stubDecodeAudio { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onAudioSourceDecoded(42, requestID: requestID)
            return 42
        }
        
        let audio = try await Audio(data: testData, dependencies: dependencies)
        XCTAssertEqual(audio.handle, 42)

        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.decodeAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeAudioCalls.first?.data, testData)
        XCTAssertEqual(commandQueue.decodeAudioCalls.first?.requestID, expectedRequestID)
    }
    
    @MainActor
    func test_init_withInvalidData_throwsError() async {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Audio.Dependencies(audioService: audioService)

        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let errorMessage = "Failed to decode audio"
        let expectedRequestID: UInt64 = 0

        let listenerDeleted = expectation(description: "failed decode listener deleted")
        commandQueue.stubDeleteAudio { handle in
            XCTAssertEqual(handle, 42)
            audioService.onAudioSourceDeleted(handle, requestID: commandQueue.deleteAudioCalls.last!.requestID)
        }
        commandQueue.stubDeleteAudioListener { handle in
            XCTAssertEqual(handle, 42)
            listenerDeleted.fulfill()
        }
        let expectation = expectation(description: "decodeAudio called with error")
        commandQueue.stubDecodeAudio { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onAudioSourceError(42, requestID: requestID, message: errorMessage)
            return 42
        }

        do {
            _ = try await Audio(data: testData, dependencies: dependencies)
            XCTFail("Error should be thrown")
        } catch AudioError.failedDecoding(let message) {
            await fulfillment(of: [expectation], timeout: 1)
            XCTAssertEqual(message, errorMessage)
        } catch {
            await fulfillment(of: [expectation], timeout: 1)
            XCTFail("Expected AudioError.failedDecoding, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [listenerDeleted], timeout: 1)
        XCTAssertEqual(commandQueue.deleteAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteAudioListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeAudioCalls.first?.data, testData)
    }

    // MARK: - Cancellation

    @MainActor
    func test_deleteAudio_whenAlreadyCancelled_throwsAudioErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = AudioService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDeleteAudio { handle in
            service.onAudioSourceDeleted(handle, requestID: commandQueue.deleteAudioCalls.last!.requestID)
        }

        let task = Task { @MainActor in
            try await service.deleteAudio(42)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected AudioError.cancelled")
        } catch AudioError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected AudioError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.deleteAudioCalls.isEmpty)
    }

    @MainActor
    func test_decodeAudio_whenAlreadyCancelled_throwsAudioErrorWithoutEnqueuing() async {
        let commandQueue = MockCommandQueue()
        let service = AudioService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        commandQueue.stubDecodeAudio { _, listener, requestID in
            listener.onAudioSourceDecoded(42, requestID: requestID)
            return 42
        }

        let task = Task { @MainActor in
            try await service.decodeAudio(from: Data([1, 2, 3]))
        }
        // The task cannot enter the main actor until this test suspends.
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected AudioError.cancelled")
        } catch AudioError.cancelled {
            // Expected for cancellation before the operation starts.
        } catch {
            XCTFail("Expected AudioError.cancelled, got \(error)")
        }
        XCTAssertTrue(commandQueue.decodeAudioCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteAudioCalls.isEmpty)
        XCTAssertTrue(commandQueue.deleteAudioListenerCalls.isEmpty)
    }

    @MainActor
    func test_decodeAudio_whenCancelled_throwsCancelledErrorAndCleansUp() async throws {
        for decodeFails in [false, true] {
            let commandQueue = MockCommandQueue()
            let audioService = AudioService(dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            ))
            let enteredContinuation = expectation(description: "decode enqueued")
            commandQueue.stubDecodeAudio { _, _, _ in
                enteredContinuation.fulfill()
                return 42
            }
            let deletionEnqueued = expectation(description: "cancelled audio deletion enqueued")
            commandQueue.stubDeleteAudio { handle in
                XCTAssertEqual(handle, 42)
                deletionEnqueued.fulfill()
            }
            let listenerDeleted = expectation(description: "cancelled audio listener deleted")
            commandQueue.stubDeleteAudioListener { handle in
                XCTAssertEqual(handle, 42)
                listenerDeleted.fulfill()
            }

            let task = Task { @MainActor in
                try await audioService.decodeAudio(from: Data([0, 1, 2, 3]))
            }
            await fulfillment(of: [enteredContinuation], timeout: 1)
            task.cancel()

            do {
                _ = try await task.value
                XCTFail("Expected AudioError.cancelled")
            } catch AudioError.cancelled {
                // Expected while the native decode is still pending.
            } catch {
                XCTFail("Expected AudioError.cancelled, got \(error)")
            }

            await fulfillment(of: [deletionEnqueued], timeout: 1)
            XCTAssertTrue(commandQueue.deleteAudioListenerCalls.isEmpty)
            let decodeCall = try XCTUnwrap(commandQueue.decodeAudioCalls.first)
            if decodeFails {
                audioService.onAudioSourceError(42, requestID: decodeCall.requestID, message: "Late decode failure")
            } else {
                audioService.onAudioSourceDecoded(42, requestID: decodeCall.requestID)
            }
            let deleteCall = try XCTUnwrap(commandQueue.deleteAudioCalls.first)
            audioService.onAudioSourceDeleted(42, requestID: deleteCall.requestID)
            await fulfillment(of: [listenerDeleted], timeout: 1)
            XCTAssertEqual(commandQueue.deleteAudioCalls.count, 1)
            XCTAssertEqual(commandQueue.deleteAudioListenerCalls.count, 1)
        }
    }

    @MainActor
    func test_deleteAudio_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDeleteAudio { handle in
            enteredContinuation.fulfill()
        }

        let task = Task { @MainActor in
            try await audioService.deleteAudio(42)
        }

        await fulfillment(of: [enteredContinuation], timeout: 1)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected AudioError.cancelled to be thrown")
        } catch let error as AudioError {
            guard case .cancelled = error else {
                XCTFail("Expected AudioError.cancelled, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AudioError.cancelled, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Lifecycle

    @MainActor
    func test_deinit_callsDeleteAudio() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let dependencies = Audio.Dependencies(audioService: audioService)
        
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        
        let decodeExpectation = expectation(description: "decodeAudio called")
        commandQueue.stubDecodeAudio { data, listener, requestID in
            XCTAssertEqual(requestID, 0)
            decodeExpectation.fulfill()
            listener.onAudioSourceDecoded(100, requestID: requestID)
            return 100
        }
        
        var audio: Audio? = try await Audio(data: testData, dependencies: dependencies)
        _ = audio

        await fulfillment(of: [decodeExpectation], timeout: 1)

        XCTAssertEqual(commandQueue.deleteAudioCalls.count, 0)
        
        let deleteExpectation = expectation(description: "deleteAudio called")
        let deleteListenerExpectation = expectation(description: "deleteAudioListener called")
        commandQueue.stubDeleteAudio { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
            guard let requestID = commandQueue.deleteAudioCalls.last?.requestID else {
                XCTFail("Missing delete audio request ID")
                return
            }
            audioService.onAudioSourceDeleted(handle, requestID: requestID)
        }
        commandQueue.stubDeleteAudioListener { handle in
            XCTAssertEqual(handle, 100)
            deleteListenerExpectation.fulfill()
        }
        
        audio = nil
        
        await fulfillment(of: [deleteExpectation, deleteListenerExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteAudioListenerCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteAudioCalls.first?.audioHandle, 100)
        XCTAssertEqual(commandQueue.deleteAudioListenerCalls.first?.audioHandle, 100)
    }
}

