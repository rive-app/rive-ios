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
        
        let expectation = expectation(description: "decodeAudio called with error")
        commandQueue.stubDecodeAudio { data, listener, requestID in
            XCTAssertEqual(requestID, 0)
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            listener.onAudioSourceError(0, requestID: requestID, message: errorMessage)
            return 0
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
        
        XCTAssertEqual(commandQueue.decodeAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.decodeAudioCalls.first?.data, testData)
    }
    
    // MARK: - Cancellation

    @MainActor
    func test_decodeAudio_whenCancelled_throwsCancelledError() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))

        let testData = Data([0x00, 0x01, 0x02, 0x03])

        let enteredContinuation = expectation(description: "entered continuation")
        commandQueue.stubDecodeAudio { data, listener, requestID in
            enteredContinuation.fulfill()
            return 0
        }

        let task = Task { @MainActor in
            try await audioService.decodeAudio(from: testData)
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

