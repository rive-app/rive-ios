//
//  File+Extensions.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

@_spi(RiveExperimental) @testable import RiveRuntime

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
                renderContext: RiveUIRenderContext(device: device),
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
