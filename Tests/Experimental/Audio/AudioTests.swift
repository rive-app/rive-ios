//
//  AudioTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class AudioTests: XCTestCase {
    
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue))
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
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue))
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
    
    @MainActor
    func test_deinit_callsDeleteAudio() async throws {
        let commandQueue = MockCommandQueue()
        let audioService = AudioService(dependencies: .init(commandQueue: commandQueue))
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
        commandQueue.stubDeleteAudio { handle in
            XCTAssertEqual(handle, 100)
            deleteExpectation.fulfill()
        }
        
        audio = nil
        
        await fulfillment(of: [deleteExpectation], timeout: 1)
        
        XCTAssertEqual(commandQueue.deleteAudioCalls.count, 1)
        XCTAssertEqual(commandQueue.deleteAudioCalls.first?.audioHandle, 100)
    }
}

