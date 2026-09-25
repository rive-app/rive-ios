import XCTest
@testable import RiveRuntime

extension Worker {
    @MainActor
    convenience init(assetDataCopier: any RiveAssetDataCopier) async throws {
        let defaultDevice = await MetalDevice.shared.defaultDevice()
        let device = try XCTUnwrap(defaultDevice?.value)
        let renderContext = RiveUIRenderContext(device: device)
        let commandQueue = CommandQueue(assetDataCopier: assetDataCopier)
        let commandServer = CommandServer(
            commandQueue: commandQueue,
            renderContext: renderContext
        )
        let workerService = WorkerService(dependencies: .init(
            commandQueue: commandQueue,
            commandServer: commandServer,
            renderingMode: .immediate(renderContext),
            messagePumpDriver: commandQueue
        ))
        self.init(dependencies: .init(workerService: workerService))
    }
}
