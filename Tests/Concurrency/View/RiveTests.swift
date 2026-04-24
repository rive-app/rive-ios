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

        let bindExpectation = expectation(description: "bindViewModelInstance called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedViewModelInstanceHandle: UInt64 = 0
        mockCommandQueue.stubBindViewModelInstance { stateMachineHandle, viewModelInstanceHandle, _ in
            capturedStateMachineHandle = stateMachineHandle
            capturedViewModelInstanceHandle = viewModelInstanceHandle
            bindExpectation.fulfill()
        }
        
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .instance(viewModelInstance)
        )
        
        await fulfillment(of: [bindExpectation], timeout: 1)
        XCTAssertEqual(capturedStateMachineHandle, 99)
        XCTAssertEqual(capturedViewModelInstanceHandle, 200)
        XCTAssertEqual(rive.viewModelInstance?.viewModelInstanceHandle, 200)
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
        
        let bindExpectation = expectation(description: "bindViewModelInstance called")
        var capturedStateMachineHandle: UInt64 = 0
        var capturedViewModelInstanceHandle: UInt64 = 0
        mockCommandQueue.stubBindViewModelInstance { stateMachineHandle, viewModelInstanceHandle, _ in
            capturedStateMachineHandle = stateMachineHandle
            capturedViewModelInstanceHandle = viewModelInstanceHandle
            bindExpectation.fulfill()
        }
        
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .auto
        )
        
        await fulfillment(of: [createViewModelInstanceExpectation, bindExpectation], timeout: 1)
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertEqual(capturedStateMachineHandle, 99)
        XCTAssertEqual(capturedViewModelInstanceHandle, 200)
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
        
        let bindExpectation = expectation(description: "bindViewModelInstance should not be called")
        bindExpectation.isInverted = true
        mockCommandQueue.stubBindViewModelInstance { _, _, _ in
            bindExpectation.fulfill()
        }
        
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
        
        await fulfillment(of: [bindExpectation, createViewModelInstanceExpectation], timeout: 1)
        XCTAssertNil(rive.viewModelInstance)
    }
    
    @MainActor
    func test_init_withDefaultDataBind_usesAuto() async throws {
        let (file, mockCommandQueue, _, _) = await File.mock(fileHandle: 123)
        let fileService = file.dependencies.fileService

        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let artboardDependencies = Artboard.Dependencies(artboardService: artboardService)
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)

        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let stateMachineDependencies = StateMachine.Dependencies(stateMachineService: stateMachineService)
        let stateMachine = StateMachine(dependencies: stateMachineDependencies, stateMachineHandle: 99)

        let createViewModelInstanceExpectation = expectation(description: "view model instance created")
        mockCommandQueue.stubCreateDefaultViewModelInstance { _, fileHandle, _, requestID in
            fileService.onViewModelInstanceInstantiated(fileHandle, requestID: requestID, viewModelInstanceHandle: 200)
            createViewModelInstanceExpectation.fulfill()
            return 200
        }
        
        let bindExpectation = expectation(description: "bindViewModelInstance called")
        mockCommandQueue.stubBindViewModelInstance { _, _, _ in
            bindExpectation.fulfill()
        }
        
        // Don't specify dataBind parameter - should default to .auto
        let rive = try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine
        )
        
        await fulfillment(of: [createViewModelInstanceExpectation, bindExpectation], timeout: 1)
        XCTAssertNotNil(rive.viewModelInstance)
        XCTAssertEqual(rive.viewModelInstance?.viewModelInstanceHandle, 200)
    }
}
