//
//  File+Extensions.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Metal
@testable import RiveRuntime

extension File {
    /// Creates mock dependencies for a File instance, including Worker setup.
    /// - Parameters:
    ///   - fileHandle: The file handle to use
    ///   - commandQueue: Optional existing mock command queue to reuse. If nil, a new one will be created.
    ///   - commandServer: Optional existing mock command server to reuse. If nil, a new one will be created.
    /// - Returns: A labeled tuple containing the File instance, mock commandQueue, and commandServer
    @MainActor
    static func mock(fileHandle: FileHandle, commandQueue: MockCommandQueue? = nil, commandServer: MockCommandServer? = nil) async -> (file: File, commandQueue: MockCommandQueue, commandServer: MockCommandServer, fileLoader: MockFileLoader) {
        let mockCommandQueue = commandQueue ?? MockCommandQueue()
        let mockCommandServer = commandServer ?? MockCommandServer()
        let device = await MetalDevice.shared.defaultDevice()!.value
        let workerService = WorkerService(
            dependencies: .init(
                commandQueue: mockCommandQueue,
                commandServer: mockCommandServer,
                renderingMode: .immediate(RiveUIRenderContext(device: device)),
                messagePumpDriver: mockCommandQueue
            )
        )
        let dependencies = Worker.Dependencies(workerService: workerService)
        let worker = Worker(dependencies: dependencies)
        
        let mockFileLoader = MockFileLoader()
        let fileService = FileService(dependencies: .init(commandQueue: mockCommandQueue, messageGate: CommandQueueMessageGate(driver: mockCommandQueue)))
        let fileDependencies = Dependencies(
            fileLoader: mockFileLoader,
            fileService: fileService
        )
        
        let file = File(dependencies: fileDependencies, fileHandle: fileHandle, worker: worker)
        
        return (file: file, commandQueue: mockCommandQueue, commandServer: mockCommandServer, fileLoader: mockFileLoader)
    }
}

// Supply parents for tests that construct handles directly rather than through File creation.
extension Artboard {
    @MainActor
    convenience init(dependencies: Dependencies, artboardHandle: ArtboardHandle) {
        let commandQueue = dependencies.artboardService.dependencies.commandQueue as! MockCommandQueue
        let workerService = WorkerService(dependencies: .init(
            commandQueue: commandQueue,
            commandServer: MockCommandServer(),
            renderingMode: .immediate(RiveUIRenderContext(device: MTLCreateSystemDefaultDevice()!)),
            messagePumpDriver: commandQueue
        ))
        let file = File(
            dependencies: .init(
                fileLoader: MockFileLoader(),
                fileService: FileService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
            ),
            fileHandle: 1,
            worker: Worker(dependencies: .init(workerService: workerService))
        )
        self.init(dependencies: dependencies, artboardHandle: artboardHandle, sourceFile: file)
    }
}

extension StateMachine {
    @MainActor
    convenience init(dependencies: Dependencies, stateMachineHandle: StateMachineHandle) {
        let service = dependencies.stateMachineService
        let artboard = Artboard(
            dependencies: .init(artboardService: ArtboardService(dependencies: .init(
                commandQueue: service.dependencies.commandQueue,
                messageGate: service.dependencies.messageGate
            ))),
            artboardHandle: 1
        )
        self.init(dependencies: dependencies, stateMachineHandle: stateMachineHandle, sourceArtboard: artboard)
    }
}
