//
//  RiveTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 1/8/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

class RiveTests: XCTestCase {
    // MARK: - Initialization Tests
    
    @MainActor
    func test_init_withAllParameters_succeeds() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)

        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)
        
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none,
            fit: .contain(alignment: .center),
            backgroundColor: Color(red: 255, green: 0, blue: 0, alpha: 255)
        )
        
        XCTAssertEqual(rive.file.fileHandle, 123)
        XCTAssertEqual(rive.artboard.artboardHandle, 42)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
        XCTAssertEqual(rive.backgroundColor.red, 255)
        XCTAssertEqual(rive.backgroundColor.green, 0)
        XCTAssertEqual(rive.backgroundColor.blue, 0)
        XCTAssertEqual(rive.backgroundColor.alpha, 255)
    }
    
    @MainActor
    func test_init_withOptionalArtboard_createsDefaultArtboard() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let artboardExpectation = expectation(description: "artboard created")
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, _, requestID in
            capturedFileHandle = fileHandle
            fileService.onArtboardInstantiated(fileHandle, requestID: requestID, artboardHandle: 42)
            artboardExpectation.fulfill()
            return 42
        }
        
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)
        
        let rive = try await Rive(
            file: file,
            artboard: nil,
            stateMachine: stateMachine,
            dataBind: .none
        )
        
        await fulfillment(of: [artboardExpectation], timeout: 1)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(rive.artboard.artboardHandle, 42)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
    }
    
    @MainActor
    func test_init_withOptionalStateMachine_createsDefaultStateMachine() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        let stateMachineExpectation = expectation(description: "state machine created")
        var capturedArtboardHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultStateMachine { artboardHandle, _, requestID in
            capturedArtboardHandle = artboardHandle
            artboardService.onStateMachineInstantiated(artboardHandle, requestID: requestID, stateMachineHandle: 99)
            stateMachineExpectation.fulfill()
            return 99
        }

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: nil,
            dataBind: .none
        )

        await fulfillment(of: [stateMachineExpectation], timeout: 1)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(rive.artboard.artboardHandle, 42)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
        XCTAssertTrue(mockCommandQueue.bindCalls.isEmpty)
    }
    
    @MainActor
    func test_init_withBothOptional_createsBothDefaults() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let artboardExpectation = expectation(description: "artboard created")
        var capturedFileHandle: UInt64 = 0
        var capturedArtboardObserver: (any ArtboardListener)?
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, observer, requestID in
            capturedFileHandle = fileHandle
            capturedArtboardObserver = observer
            fileService.onArtboardInstantiated(fileHandle, requestID: requestID, artboardHandle: 42)
            artboardExpectation.fulfill()
            return 42
        }

        let stateMachineExpectation = expectation(description: "state machine created")
        var capturedArtboardHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultStateMachine { artboardHandle, _, requestID in
            capturedArtboardHandle = artboardHandle
            capturedArtboardObserver?.onStateMachineInstantiated(artboardHandle, requestID: requestID, stateMachineHandle: 99)
            stateMachineExpectation.fulfill()
            return 99
        }
        
        let rive = try await Rive(
            file: file,
            artboard: nil,
            stateMachine: nil,
            dataBind: .none
        )
        
        await fulfillment(of: [artboardExpectation, stateMachineExpectation], timeout: 1)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(rive.artboard.artboardHandle, 42)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
    }
    
    @MainActor
    func test_init_withDataBindViewModelInstance_bindsToStateMachine() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)

        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let viewModelInstance = ViewModelInstance(
            handle: 200,
            dependencies: .init(viewModelInstanceService: viewModelInstanceService)
        )

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .instance(viewModelInstance)
        )
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.stateMachineHandle, 99)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 200)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertTrue(rive.stateMachine.mainBinding === viewModelInstance)
        XCTAssertTrue(rive.viewModelInstance === viewModelInstance)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)

        let modernRive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)
        let unboundRive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine, dataBind: .none)

        XCTAssertNil(modernRive.viewModelInstance)
        XCTAssertNil(unboundRive.viewModelInstance)
        XCTAssertTrue(rive.viewModelInstance === viewModelInstance)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
    }

    @MainActor
    func test_init_withFile_createsBoundDefaultsWithoutLookingUpInstances() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        var artboardObserver: (any ArtboardListener)?
        mockCommandQueue.stubCreateDefaultArtboard { fileHandle, observer, requestID in
            artboardObserver = observer
            fileService.onArtboardInstantiated(fileHandle, requestID: requestID, artboardHandle: 42)
            return 42
        }
        mockCommandQueue.stubCreateDefaultStateMachine { artboardHandle, observer, requestID in
            artboardObserver?.onStateMachineInstantiated(artboardHandle, requestID: requestID, stateMachineHandle: 99)
            return 99
        }
        var didCreateDefaultViewModelInstance = false
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
            didCreateDefaultViewModelInstance = true
            fileService.onViewModelInstanceInstantiated(
                fileHandle,
                requestID: requestID,
                viewModelInstanceHandle: 300
            )
            return 300
        }

        let rive = try await Rive(file: file)

        XCTAssertEqual(rive.artboard.artboardHandle, 42)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.globalViewModelInstanceCalls.isEmpty)
        XCTAssertFalse(didCreateDefaultViewModelInstance)
        XCTAssertNil(rive.viewModelInstance)
    }

    @MainActor
    func test_init_withArtboard_createsBoundDefaultStateMachineWithoutLookingUpInstances() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)

        mockCommandQueue.stubCreateDefaultStateMachine { artboardHandle, observer, requestID in
            artboardService.onStateMachineInstantiated(artboardHandle, requestID: requestID, stateMachineHandle: 99)
            return 99
        }
        var didCreateDefaultViewModelInstance = false
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
            didCreateDefaultViewModelInstance = true
            fileService.onViewModelInstanceInstantiated(
                fileHandle,
                requestID: requestID,
                viewModelInstanceHandle: 300
            )
            return 300
        }

        let rive = try await Rive(file: file, artboard: artboard)

        XCTAssertTrue(rive.artboard === artboard)
        XCTAssertEqual(rive.stateMachine.stateMachineHandle, 99)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.globalViewModelInstanceCalls.isEmpty)
        XCTAssertFalse(didCreateDefaultViewModelInstance)
        XCTAssertNil(rive.viewModelInstance)
    }

    @MainActor
    func test_init_withStateMachine_doesNotRebindOrLookUpInstances() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachine = StateMachine(dependencies: .init(stateMachineService: stateMachineService), stateMachineHandle: 99)

        let rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)

        XCTAssertTrue(rive.artboard === artboard)
        XCTAssertTrue(rive.stateMachine === stateMachine)
        XCTAssertTrue(mockCommandQueue.bindCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.globalViewModelInstanceCalls.isEmpty)
        XCTAssertNil(rive.viewModelInstance)
    }

    @MainActor
    func test_init_withStateMachineAndCachedMain_doesNotExposeCachedInstanceThroughLegacyGetter() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboard = Artboard(dependencies: .init(artboardService: artboardService), artboardHandle: 42)
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachine = StateMachine(dependencies: .init(stateMachineService: stateMachineService), stateMachineHandle: 99)
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let viewModelInstance = ViewModelInstance(
            handle: 200,
            dependencies: .init(viewModelInstanceService: viewModelInstanceService)
        )
        try await stateMachine.bindViewModelInstances(main: viewModelInstance)

        let rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)

        XCTAssertNil(rive.viewModelInstance)
        XCTAssertTrue(stateMachine.mainBinding === viewModelInstance)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.globalViewModelInstanceCalls.isEmpty)
    }

    // MARK: - DataBind Tests
    
    @MainActor
    func test_init_withDataBindAuto_whenViewModelInstanceCreated_bindsToStateMachine() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)

        let createViewModelInstanceExpectation = expectation(description: "view model instance created")
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        mockCommandQueue.stubCreateDefaultViewModelInstance { artboardHandle, fileHandle, _, requestID in
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 200)
            createViewModelInstanceExpectation.fulfill()
            return 200
        }
        
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .auto
        )
        
        await fulfillment(of: [createViewModelInstanceExpectation], timeout: 1)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.stateMachineHandle, 99)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 200)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertEqual(rive.viewModelInstance?.viewModelInstanceHandle, 200)
    }
    
    @MainActor
    func test_init_withDataBindNone_doesNotBind() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)
        
        let createViewModelInstanceExpectation = expectation(description: "createViewModelInstance should not be called")
        createViewModelInstanceExpectation.isInverted = true
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, _, _, _ in
            createViewModelInstanceExpectation.fulfill()
            return 200
        }
        
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .none
        )
        
        await fulfillment(of: [createViewModelInstanceExpectation], timeout: 1)
        XCTAssertTrue(mockCommandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.bindCalls.isEmpty)
        XCTAssertNil(rive.viewModelInstance)
    }
    
    @MainActor
    func test_init_withoutDataBind_usesNewInitializer() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)

        var didCreateDefaultViewModelInstance = false
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
            didCreateDefaultViewModelInstance = true
            fileService.onViewModelInstanceInstantiated(
                fileHandle,
                requestID: requestID,
                viewModelInstanceHandle: 300
            )
            return 300
        }

        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine
        )

        XCTAssertFalse(didCreateDefaultViewModelInstance)
        XCTAssertTrue(mockCommandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.bindCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.mainViewModelInstanceCalls.isEmpty)
        XCTAssertNil(rive.viewModelInstance)
        XCTAssertTrue(mockCommandQueue.globalViewModelInstanceCalls.isEmpty)
    }
}
