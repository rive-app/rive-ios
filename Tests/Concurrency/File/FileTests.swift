//
//  FileTests.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/30/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

class FileTests: XCTestCase {
    @MainActor
    func test_init_withValidData_succeeds() async throws {
        let mockCommandQueue = MockCommandQueue()
        let mockFileLoader = MockFileLoader()
        let mockCommandServer = MockCommandServer()
        
        let fileService = FileService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        
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
                renderContext: RiveUIRenderContext(device: MetalDevice.shared.defaultDevice()!.value),
                messagePumpDriver: mockCommandQueue
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
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 1)
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
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 1)
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
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 42)
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
    func test_createDefaultArtboard_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createDefaultArtboard called")
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, _, requestID in
            capturedFileHandle = fileHandle
            fileService.onArtboardInstantiated(fileHandle, requestID: requestID, artboardHandle: 42)
            expectation.fulfill()
            return 42
        }

        let artboard = try await file.createArtboard()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(artboard.artboardHandle, 42)
    }

    @MainActor
    func test_createArtboardNamed_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createArtboardNamed called")
        var capturedName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateArtboardNamed { name, fileHandle, _, requestID in
            capturedName = name
            capturedFileHandle = fileHandle
            fileService.onArtboardInstantiated(fileHandle, requestID: requestID, artboardHandle: 42)
            expectation.fulfill()
            return 42
        }

        let artboard = try await file.createArtboard("Test Artboard")
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedName, "Test Artboard")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(artboard.artboardHandle, 42)
    }

    @MainActor
    func test_createDefaultArtboard_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createDefaultArtboard called")
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "file 123 not found when trying to create artboard")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createArtboard()
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidArtboard(let message) = error else {
                XCTFail("Expected FileError.invalidArtboard, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("not found"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createArtboardNamed_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createArtboardNamed called")
        mockCommandQueue.stubCreateArtboardNamed { _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "artboard \"Invalid Artboard\" not found.")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createArtboard("Invalid Artboard")
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidArtboard(let message) = error else {
                XCTFail("Expected FileError.invalidArtboard, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Invalid Artboard"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    // MARK: - createViewModelInstance success paths

    @MainActor
    func test_createBlankViewModelInstanceForArtboard_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createBlankViewModelInstance called")
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateBlankViewModelInstance { artboardHandle, fileHandle, _, requestID in
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 99)
            expectation.fulfill()
            return 99
        }

        let vmi = try await file.createViewModelInstance(.blank(from: .artboardDefault(artboard)))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 99)
    }

    @MainActor
    func test_createBlankViewModelInstanceNamed_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createBlankViewModelInstanceNamed called")
        var capturedViewModelName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateBlankViewModelInstanceNamed { viewModelName, fileHandle, _, requestID in
            capturedViewModelName = viewModelName
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 100)
            expectation.fulfill()
            return 100
        }

        let vmi = try await file.createViewModelInstance(.blank(from: .name("TestViewModel")))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedViewModelName, "TestViewModel")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 100)
    }

    @MainActor
    func test_createDefaultViewModelInstanceForArtboard_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createDefaultViewModelInstance called")
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultViewModelInstance { artboardHandle, fileHandle, _, requestID in
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 101)
            expectation.fulfill()
            return 101
        }

        let vmi = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 101)
    }

    @MainActor
    func test_createDefaultViewModelInstanceNamed_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createDefaultViewModelInstanceNamed called")
        var capturedViewModelName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultViewModelInstanceNamed { viewModelName, fileHandle, _, requestID in
            capturedViewModelName = viewModelName
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 102)
            expectation.fulfill()
            return 102
        }

        let vmi = try await file.createViewModelInstance(.viewModelDefault(from: .name("TestViewModel")))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedViewModelName, "TestViewModel")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 102)
    }

    @MainActor
    func test_createNamedViewModelInstanceForArtboard_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createViewModelInstanceNamedForArtboard called")
        var capturedInstanceName: String = ""
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateViewModelInstanceNamedForArtboard { instanceName, artboardHandle, fileHandle, _, requestID in
            capturedInstanceName = instanceName
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 103)
            expectation.fulfill()
            return 103
        }

        let vmi = try await file.createViewModelInstance(.name("TestInstance", from: .artboardDefault(artboard)))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedInstanceName, "TestInstance")
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 103)
    }

    @MainActor
    func test_createNamedViewModelInstance_resumesOnInstantiatedCallback() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createViewModelInstanceNamed called")
        var capturedInstanceName: String = ""
        var capturedViewModelName: String = ""
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateViewModelInstanceNamed { instanceName, viewModelName, fileHandle, _, requestID in
            capturedInstanceName = instanceName
            capturedViewModelName = viewModelName
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 104)
            expectation.fulfill()
            return 104
        }

        let vmi = try await file.createViewModelInstance(.name("TestInstance", from: .name("TestViewModel")))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(capturedInstanceName, "TestInstance")
        XCTAssertEqual(capturedViewModelName, "TestViewModel")
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(vmi.viewModelInstanceHandle, 104)
    }

    // MARK: - createViewModelInstance error paths

    @MainActor
    func test_createBlankViewModelInstanceForArtboard_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createBlankViewModelInstance called")
        mockCommandQueue.stubCreateBlankViewModelInstance { _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "view model not found")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.blank(from: .artboardDefault(artboard)))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("not found"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createBlankViewModelInstanceNamed_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createBlankViewModelInstanceNamed called")
        mockCommandQueue.stubCreateBlankViewModelInstanceNamed { _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "view model \"Invalid\" not found")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.blank(from: .name("Invalid")))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Invalid"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createDefaultViewModelInstanceForArtboard_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createDefaultViewModelInstance called")
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "no default view model for artboard")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("no default"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createDefaultViewModelInstanceNamed_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createDefaultViewModelInstanceNamed called")
        mockCommandQueue.stubCreateDefaultViewModelInstanceNamed { _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "view model \"Missing\" not found")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.viewModelDefault(from: .name("Missing")))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Missing"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createNamedViewModelInstanceForArtboard_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        let expectation = expectation(description: "createViewModelInstanceNamedForArtboard called")
        mockCommandQueue.stubCreateViewModelInstanceNamedForArtboard { _, _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "instance \"BadInstance\" not found")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.name("BadInstance", from: .artboardDefault(artboard)))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("BadInstance"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_createNamedViewModelInstance_whenServerReportsError_throws() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let expectation = expectation(description: "createViewModelInstanceNamed called")
        mockCommandQueue.stubCreateViewModelInstanceNamed { _, _, fileHandle, _, requestID in
            fileService.onFileError(fileHandle, requestID: requestID, message: "instance \"BadInstance\" not found in \"TestVM\"")
            expectation.fulfill()
            return 0
        }

        do {
            _ = try await file.createViewModelInstance(.name("BadInstance", from: .name("TestVM")))
            XCTFail("Expected FileError to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance(let message) = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("BadInstance"))
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func test_equality_withSameFileHandle_returnsTrue() async {
        let (file1, _, _, _) = await File.mock(fileHandle: 1)
        let (file2, _, _, _) = await File.mock(fileHandle: 1)

        XCTAssertEqual(file1, file2)
    }

    @MainActor
    func test_equality_withDifferentFileHandles_returnsFalse() async {
        let (file1, _, _, _) = await File.mock(fileHandle: 1)
        let (file2, _, _, _) = await File.mock(fileHandle: 2)

        XCTAssertNotEqual(file1, file2)
    }

    @MainActor
    func test_deinit_deletesFileAndThenDeletesFileListener() async {
        let deleteFileExpectation = expectation(description: "deleteFile called")
        let deleteFileListenerExpectation = expectation(description: "deleteFileListener called")
        let mockCommandQueue = MockCommandQueue()
        let mockCommandServer = MockCommandServer()
        var file: File? = await File.mock(
            fileHandle: 123,
            commandQueue: mockCommandQueue,
            commandServer: mockCommandServer
        ).file
        let fileService = file!.dependencies.fileService

        mockCommandQueue.stubDeleteFile { fileHandle, requestID in
            XCTAssertEqual(fileHandle, 123)
            XCTAssertTrue(
                mockCommandQueue.deleteFileListenerCalls.isEmpty,
                "Listener should not be removed before delete callback is received"
            )
            deleteFileExpectation.fulfill()
            fileService.onFileDeleted(fileHandle, requestID: requestID)
        }

        mockCommandQueue.stubDeleteFileListener { fileHandle in
            XCTAssertEqual(fileHandle, 123)
            deleteFileListenerExpectation.fulfill()
        }

        weak var weakFile = file
        autoreleasepool {
            file = nil
        }
        XCTAssertNil(weakFile)

        await fulfillment(of: [deleteFileExpectation, deleteFileListenerExpectation], timeout: 1)
        XCTAssertEqual(mockCommandQueue.deleteFileCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.deleteFileListenerCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.deleteFileListenerCalls.first?.fileHandle, 123)
    }
    
    @MainActor
    func test_getDefaultViewModelInfo_withValidArtboard_returnsViewModelInfo() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
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
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 456)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
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
