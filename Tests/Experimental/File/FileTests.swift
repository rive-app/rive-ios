//
//  FileTests.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/30/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @preconcurrency @testable import RiveRuntime

class FileTests: XCTestCase {
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let mockCommandQueue = MockCommandQueue()
        let mockFileLoader = MockFileLoader()
        let mockCommandServer = MockCommandServer()
        
        let fileService = FileService(dependencies: .init(commandQueue: mockCommandQueue))
        
        let dependencies = File.Dependencies(
            fileLoader: mockFileLoader,
            fileService: fileService
        )
        
        let testData = Data([0x52, 0x49, 0x56, 0x45]) // RIVE file header
        let expectedRequestID: UInt64 = 0
        
        let expectation = expectation(description: "loadFile called")
        mockCommandQueue.stubLoadFile { data, listener, requestID in
            XCTAssertEqual(data, testData)
            XCTAssertEqual(requestID, expectedRequestID)
            expectation.fulfill()
            fileService.onFileLoaded(42, requestID: requestID)
            return 42
        }
        
        // Mock the file loader to return test data
        mockFileLoader.stubLoad {
            return testData
        }
        
        let workerService = await WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderContext: RiveRenderContext(device: MetalDevice.shared.defaultDevice()!)
            )
        )
        let workerDependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: workerDependencies)
        
        let file = try await File(dependencies: dependencies, worker: worker)
        XCTAssertEqual(file.fileHandle, 42)

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_getArtboardNames_withValidFileHandle_returnsArtboardNames() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 1)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to trigger the onArtboardsListed callback
        let expectation = expectation(description: "artboard names received")
        mockCommandQueue.stubRequestArtboardNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 1)
            // Simulate the callback from the command queue
            fileService.onArtboardsListed(1, requestID: requestID, names: ["Artboard 1", "Artboard 2", "Artboard 3"])
            expectation.fulfill()
        }
        
        let artboardNames = try await file.getArtboardNames()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(artboardNames, ["Artboard 1", "Artboard 2", "Artboard 3"])
    }

    @MainActor
    func test_getArtboardNames_withEmptyArtboardList_returnsEmptyArray() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 1)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to trigger the onArtboardsListed callback
        let expectation = expectation(description: "artboard names received")
        mockCommandQueue.stubRequestArtboardNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 1)
            // Simulate the callback from the command queue
            fileService.onArtboardsListed(1, requestID: requestID, names: [])
            expectation.fulfill()
        }
        
        let artboardNames = try await file.getArtboardNames()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(artboardNames.isEmpty)
    }

    @MainActor
    func test_getArtboardNames_passesCorrectFileHandle() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 42)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to trigger the onArtboardsListed callback
        let expectation = expectation(description: "artboard names received")
        mockCommandQueue.stubRequestArtboardNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 42)
            // Simulate the callback from the command queue
            fileService.onArtboardsListed(42, requestID: requestID, names: ["Test Artboard"])
            expectation.fulfill()
        }
        
        _ = try await file.getArtboardNames()
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    @MainActor
    func test_createDefaultArtboard_returnsArtboardWithCorrectHandle() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        
        // Mock the command queue to return a specific artboard handle and capture the file handle
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, _ in
            capturedFileHandle = fileHandle
            return 42 // Return a specific artboard handle
        }
        
        let artboard = try await file.createArtboard()
        XCTAssertNotNil(artboard)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(artboard.artboardHandle, 42)
    }

    @MainActor
    func test_createArtboardNamed_returnsArtboardWithCorrectName() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to return artboard names for validation
        let expectation = expectation(description: "artboard names received")
        mockCommandQueue.stubRequestArtboardNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue
            fileService.onArtboardsListed(123, requestID: requestID, names: ["Test Artboard", "Another Artboard"])
            expectation.fulfill()
        }
        
        // Mock the command queue to return a specific artboard handle and capture parameters
        var capturedName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateArtboardNamed { name, fileHandle, _ in
            capturedName = name
            capturedFileHandle = fileHandle
            return 42 // Return a specific artboard handle
        }
        
        let artboard = try await file.createArtboard("Test Artboard")
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertNotNil(artboard)
        XCTAssertEqual(capturedName, "Test Artboard")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(artboard.artboardHandle, 42)
    }
    
    @MainActor
    func test_createArtboardNamed_withInvalidName_throwsError() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to return artboard names that don't include the requested name
        let expectation = expectation(description: "artboard names received")
        mockCommandQueue.stubRequestArtboardNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue with names that don't include "Invalid Artboard"
            fileService.onArtboardsListed(123, requestID: requestID, names: ["Valid Artboard 1", "Valid Artboard 2"])
            expectation.fulfill()
        }
        
        do {
            _ = try await file.createArtboard("Invalid Artboard")
            XCTFail("Expected FileError.invalidArtboard to be thrown")
        } catch let error as FileError {
            if case .invalidArtboard(let name) = error {
                XCTAssertEqual(name, "Invalid Artboard")
            } else {
                XCTFail("Expected FileError.invalidArtboard(\"Invalid Artboard\"), got \(error)")
            }
        } catch {
            XCTFail("Expected FileError.invalidArtboard, got \(type(of: error)): \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    @MainActor
    func test_createViewModelInstance_returnsViewModelInstanceWithCorrectHandles() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        // Mock the command queue to return a specific view model instance handle and capture parameters
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateBlankViewModelInstance { artboardHandle, fileHandle, _, _ in
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            return 99 // Return a specific view model instance handle
        }
        
        let viewModelInstance = try await file.createViewModelInstance(.blank(from: .artboardDefault(artboard)))
        XCTAssertNotNil(viewModelInstance)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        
        // Test creating view model instance by name
        var capturedViewModelName: String = ""
        var capturedFileHandleForName: UInt64 = 0
        mockCommandQueue.stubCreateBlankViewModelInstanceNamed { viewModelName, fileHandle, _, _ in
            capturedViewModelName = viewModelName
            capturedFileHandleForName = fileHandle
            return 100 // Return a specific view model instance handle
        }
        
        let viewModelInstanceByName = try await file.createViewModelInstance(.blank(from: .name("TestViewModel")))
        XCTAssertNotNil(viewModelInstanceByName)
        XCTAssertEqual(capturedViewModelName, "TestViewModel")
        XCTAssertEqual(capturedFileHandleForName, 123)
        
        // Test creating default view model instance for artboard
        var capturedArtboardHandleForDefault: UInt64 = 0
        var capturedFileHandleForDefault: UInt64 = 0
        mockCommandQueue.stubCreateDefaultViewModelInstance { artboardHandle, fileHandle, _, _ in
            capturedArtboardHandleForDefault = artboardHandle
            capturedFileHandleForDefault = fileHandle
            return 101 // Return a specific view model instance handle
        }
        
        let defaultViewModelInstance = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
        XCTAssertNotNil(defaultViewModelInstance)
        XCTAssertEqual(capturedArtboardHandleForDefault, 42)
        XCTAssertEqual(capturedFileHandleForDefault, 123)
        
        // Test creating default view model instance by name
        var capturedViewModelNameForDefault: String = ""
        var capturedFileHandleForDefaultName: UInt64 = 0
        mockCommandQueue.stubCreateDefaultViewModelInstanceNamed { viewModelName, fileHandle, _, _ in
            capturedViewModelNameForDefault = viewModelName
            capturedFileHandleForDefaultName = fileHandle
            return 102 // Return a specific view model instance handle
        }
        
        let defaultViewModelInstanceByName = try await file.createViewModelInstance(.viewModelDefault(from: .name("TestDefaultViewModel")))
        XCTAssertNotNil(defaultViewModelInstanceByName)
        XCTAssertEqual(capturedViewModelNameForDefault, "TestDefaultViewModel")
        XCTAssertEqual(capturedFileHandleForDefaultName, 123)
    }
    
    @MainActor
    func test_createViewModelInstance_withNamedInstanceAndViewModel_returnsViewModelInstanceWithCorrectHandles() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to return view model names for validation
        let viewModelNamesExpectation = expectation(description: "view model names received")
        mockCommandQueue.stubRequestViewModelNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue
            fileService.onViewModelsListed(123, requestID: requestID, names: ["TestViewModel", "AnotherViewModel"])
            viewModelNamesExpectation.fulfill()
        }
        
        // Mock the command queue to return instance names for validation
        let instanceNamesExpectation = expectation(description: "instance names received")
        mockCommandQueue.stubRequestViewModelInstanceNames { fileHandle, viewModelName, requestID in
            XCTAssertEqual(fileHandle, 123)
            XCTAssertEqual(viewModelName, "TestViewModel")
            // Simulate the callback from the command queue
            fileService.onViewModelInstanceNamesListed(123, requestID: requestID, viewModelName: "TestViewModel", names: ["TestInstance", "AnotherInstance"])
            instanceNamesExpectation.fulfill()
        }
        
        // Mock the command queue to return a specific view model instance handle and capture parameters
        var capturedInstanceName: String = ""
        var capturedViewModelName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateViewModelInstanceNamed { instanceName, viewModelName, fileHandle, _, _ in
            capturedInstanceName = instanceName
            capturedViewModelName = viewModelName
            capturedFileHandle = fileHandle
            return 103 // Return a specific view model instance handle
        }
        
        let viewModelInstance = try await file.createViewModelInstance(.name("TestInstance", from: .name("TestViewModel")))
        await fulfillment(of: [viewModelNamesExpectation, instanceNamesExpectation], timeout: 1)
        XCTAssertNotNil(viewModelInstance)
        XCTAssertEqual(capturedInstanceName, "TestInstance")
        XCTAssertEqual(capturedViewModelName, "TestViewModel")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(viewModelInstance.viewModelInstanceHandle, 103)
    }
    
    @MainActor
    func test_createViewModelInstance_withInvalidViewModelName_throwsError() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to return view model names that don't include the requested name
        let expectation = expectation(description: "view model names received")
        mockCommandQueue.stubRequestViewModelNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue with names that don't include "InvalidViewModel"
            fileService.onViewModelsListed(123, requestID: requestID, names: ["ValidViewModel1", "ValidViewModel2"])
            expectation.fulfill()
        }
        
        do {
            _ = try await file.createViewModelInstance(.name("TestInstance", from: .name("InvalidViewModel")))
            XCTFail("Expected FileError.invalidViewModel to be thrown")
        } catch FileError.invalidViewModel(let name) {
            XCTAssertEqual(name, "InvalidViewModel")
        } catch {
            XCTFail("Expected FileError.invalidViewModel, got \(type(of: error)): \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    @MainActor
    func test_createViewModelInstance_withInvalidInstanceName_throwsError() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        
        // Mock the command queue to return view model names for validation
        let viewModelNamesExpectation = expectation(description: "view model names received")
        mockCommandQueue.stubRequestViewModelNames { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue
            fileService.onViewModelsListed(123, requestID: requestID, names: ["TestViewModel"])
            viewModelNamesExpectation.fulfill()
        }
        
        // Mock the command queue to return instance names that don't include the requested name
        let instanceNamesExpectation = expectation(description: "instance names received")
        mockCommandQueue.stubRequestViewModelInstanceNames { fileHandle, viewModelName, requestID in
            XCTAssertEqual(fileHandle, 123)
            XCTAssertEqual(viewModelName, "TestViewModel")
            // Simulate the callback from the command queue with names that don't include "InvalidInstance"
            fileService.onViewModelInstanceNamesListed(123, requestID: requestID, viewModelName: "TestViewModel", names: ["ValidInstance1", "ValidInstance2"])
            instanceNamesExpectation.fulfill()
        }
        
        do {
            _ = try await file.createViewModelInstance(.name("InvalidInstance", from: .name("TestViewModel")))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch FileError.invalidViewModelInstance(let name) {
            XCTAssertEqual(name, "InvalidInstance")
        } catch {
            XCTFail("Expected FileError.invalidViewModelInstance, got \(type(of: error)): \(error)")
        }
        
        await fulfillment(of: [viewModelNamesExpectation, instanceNamesExpectation], timeout: 1)
    }

    @MainActor
    func test_equality_withSameFileHandle_returnsTrue() {
        let (file1, _, _, _) = File.mock(fileHandle: 1)
        let (file2, _, _, _) = File.mock(fileHandle: 1)
        
        XCTAssertEqual(file1, file2)
    }

    @MainActor
    func test_equality_withDifferentFileHandles_returnsFalse() {
        let (file1, _, _, _) = File.mock(fileHandle: 1)
        let (file2, _, _, _) = File.mock(fileHandle: 2)
        
        XCTAssertNotEqual(file1, file2)
    }
    
    @MainActor
    func test_getDefaultViewModelInfo_withValidArtboard_returnsViewModelInfo() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 123)
        
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        // Mock the command queue to trigger the onDefaultViewModelInfoReceived callback
        let expectation = expectation(description: "default view model info received")
        mockCommandQueue.stubRequestDefaultViewModelInfo { artboardHandle, fileHandle, requestID in
            XCTAssertEqual(artboardHandle, 42)
            XCTAssertEqual(fileHandle, 123)
            // Simulate the callback from the command queue
            artboardService.onDefaultViewModelInfoReceived(artboardHandle, requestID: requestID, viewModelName: "TestViewModel", instanceName: "TestInstance")
            expectation.fulfill()
        }
        
        let (viewModelName, instanceName) = try await file.getDefaultViewModelInfo(for: artboard)
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(viewModelName, "TestViewModel")
        XCTAssertEqual(instanceName, "TestInstance")
        
        // Verify that the request was tracked
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.first?.artboardHandle, 42)
        XCTAssertEqual(mockCommandQueue.requestDefaultViewModelInfoCalls.first?.fileHandle, 123)
    }
    
    @MainActor
    func test_getDefaultViewModelInfo_passesCorrectArtboardAndFileHandles() async throws {
        let (file, mockCommandQueue, _, _) = File.mock(fileHandle: 456)
        
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 789)
        
        // Mock the command queue to verify correct handles are passed
        let expectation = expectation(description: "default view model info received")
        mockCommandQueue.stubRequestDefaultViewModelInfo { artboardHandle, fileHandle, requestID in
            XCTAssertEqual(artboardHandle, 789)
            XCTAssertEqual(fileHandle, 456)
            // Simulate the callback from the command queue
            artboardService.onDefaultViewModelInfoReceived(artboardHandle, requestID: requestID, viewModelName: "AnotherViewModel", instanceName: "AnotherInstance")
            expectation.fulfill()
        }
        
        _ = try await file.getDefaultViewModelInfo(for: artboard)
        await fulfillment(of: [expectation], timeout: 1)
    }

}
