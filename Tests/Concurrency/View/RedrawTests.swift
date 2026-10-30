import MetalKit
import XCTest
@testable import RiveRuntime

final class RedrawTests: XCTestCase {
    @MainActor
    func test_pausedBootstrap_retriesWithoutAdvancingAgain() async throws {
        let fixture = try await RedrawFixture()

        fixture.draw()
        XCTAssertTrue(fixture.renderer.configurations.isEmpty)
        XCTAssertEqual(fixture.metalView.acquisitionCount, 1)
        XCTAssertEqual(fixture.metalView.invalidationCount, 0)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.map(\.time), [0])

        await drainMainQueue()
        XCTAssertEqual(fixture.metalView.invalidationCount, 1)

        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.draw()
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.metalView.acquisitionCount, 2)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.map(\.time), [0])
        XCTAssertTrue(fixture.view.isPaused)
        XCTAssertTrue(fixture.controller.isPaused)
    }

    @MainActor
    func test_newerSubmission_consumesOlderQueuedRetry() async throws {
        let fixture = try await RedrawFixture()
        fixture.draw()

        let newSize = CGSize(width: 2, height: 3)
        fixture.metalView.drawableSize = newSize
        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.metalView.invalidationCount = 0
        fixture.draw()

        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.renderer.configurations.first?.size, newSize)
        await drainMainQueue()
        XCTAssertEqual(fixture.metalView.invalidationCount, 0)

        fixture.draw()
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.metalView.acquisitionCount, 2)
    }

    @MainActor
    func test_exhaustedBudget_retriesAfterFramesRetire() async throws {
        let fixture = try await RedrawFixture()
        let coordinator = try XCTUnwrap(fixture.metalView.drawableCoordinator)
        let layer = try XCTUnwrap(fixture.metalView.layer as? CAMetalLayer)
        let drawable = try fixture.makeDrawable()
        fixture.metalView.drawable = drawable
        var occupiedFrames = try (0..<layer.maximumDrawableCount).map { _ in
            try XCTUnwrap(coordinator.beginFrame { drawable })
        }

        withExtendedLifetime(occupiedFrames, fixture.draw)
        XCTAssertEqual(fixture.metalView.acquisitionCount, 0)
        XCTAssertTrue(fixture.renderer.configurations.isEmpty)
        await drainMainQueue()
        XCTAssertEqual(fixture.metalView.invalidationCount, 1)

        // The next acquisition drains the discarded frames and restores capacity.
        occupiedFrames.removeAll()
        fixture.draw()
        XCTAssertEqual(fixture.metalView.acquisitionCount, 1)
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
    }

    @MainActor
    func test_repeatedAcquisitionFailures_requestInvalidationWithoutRecursiveDrawing() async throws {
        let fixture = try await RedrawFixture()

        for attempt in 1...3 {
            fixture.draw()
            XCTAssertEqual(fixture.metalView.acquisitionCount, attempt)
            XCTAssertEqual(fixture.metalView.invalidationCount, attempt - 1)
            await drainMainQueue()
            XCTAssertEqual(fixture.metalView.invalidationCount, attempt)
            XCTAssertEqual(fixture.metalView.acquisitionCount, attempt)
        }

        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.draw()
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
    }

    @MainActor
    func test_pendingRedraw_waitsWhileOffscreen() async throws {
        let fixture = try await RedrawFixture()
        fixture.draw()
        await drainMainQueue()

        fixture.view.isOnscreenForTesting = false
        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.draw()
        XCTAssertEqual(fixture.metalView.acquisitionCount, 1)
        XCTAssertTrue(fixture.renderer.configurations.isEmpty)

        fixture.view.isOnscreenForTesting = true
        fixture.draw()
        XCTAssertEqual(fixture.metalView.acquisitionCount, 2)
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
    }

    @MainActor
    func test_zeroSize_doesNotConsumePausedBootstrap() async throws {
        let fixture = try await RedrawFixture()
        fixture.metalView.drawableSize = .zero
        fixture.draw()
        XCTAssertTrue(fixture.commandQueue.advanceStateMachineCalls.isEmpty)
        XCTAssertEqual(fixture.metalView.acquisitionCount, 0)

        fixture.metalView.drawableSize = CGSize(width: 1, height: 1)
        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.draw()
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.map(\.time), [0])
    }

    @MainActor
    func test_settleAfterAcquisitionFailure_doesNotDiscardFinalFrame() async throws {
        let fixture = try await RedrawFixture(isPaused: false)
        fixture.draw()

        let settled = expectation(description: "Controller receives settle notification")
        fixture.controller.onHasPendingSettleForTesting = { settled.fulfill() }
        fixture.stateMachineService.onStateMachineSettled(123, requestID: 1)
        await fulfillment(of: [settled], timeout: 1)
        fixture.controller.onHasPendingSettleForTesting = nil
        fixture.controller.resolveForTesting()
        XCTAssertTrue(fixture.controller.isSettled)

        fixture.metalView.drawable = try fixture.makeDrawable()
        fixture.draw()
        XCTAssertEqual(fixture.renderer.configurations.count, 1)
        XCTAssertEqual(fixture.commandQueue.advanceStateMachineCalls.count, 1)
        XCTAssertTrue(fixture.controller.isSettled)
    }

    @MainActor
    func test_replacementDuringAcquisitionFailure_doesNotRetryOldConfiguration() async throws {
        let fixture = try await RedrawFixture()
        let delegate = RedrawReplacementDelegate()
        delegate.replacement = fixture.controller.rive
        fixture.view.delegate = delegate

        withExtendedLifetime(delegate, fixture.draw)
        XCTAssertTrue(fixture.view.rive === fixture.controller.rive)
        await drainMainQueue()
        XCTAssertEqual(fixture.metalView.invalidationCount, 0)
    }

    @MainActor
    private func drainMainQueue() async {
        let drained = expectation(description: "Queued invalidation has executed")
        DispatchQueue.main.async { drained.fulfill() }
        await fulfillment(of: [drained], timeout: 1)
    }
}

@MainActor
private struct RedrawFixture {
    let view: RiveUIView
    let controller: RiveController
    let metalView: RedrawMetalView
    let renderer = RedrawRenderer()
    let commandQueue: MockCommandQueue
    let stateMachineService: StateMachineService

    init(isPaused: Bool = true) async throws {
        guard let device = await MetalDevice.shared.defaultDevice()?.value else {
            throw XCTSkip("Metal is unavailable")
        }
        let (file, commandQueue, _, _) = await File.mock(fileHandle: 123)
        let messageGate = CommandQueueMessageGate(driver: commandQueue)
        let artboardService = ArtboardService(dependencies: .init(commandQueue: commandQueue, messageGate: messageGate))
        let artboard = Artboard(
            dependencies: .init(artboardService: artboardService),
            artboardHandle: 42,
            sourceFile: file
        )
        let stateMachineService = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: messageGate))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: stateMachineService),
            stateMachineHandle: 123,
            sourceArtboard: artboard
        )
        let rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine, dataBind: .none)
        let view = RiveUIView(rive: nil, isPaused: isPaused)
        self.view = view
        self.commandQueue = commandQueue
        self.stateMachineService = stateMachineService
        controller = RiveController(rive: rive, delegate: view)
        metalView = RedrawMetalView(frame: .zero, device: device)

        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        metalView.autoResizeDrawable = false
        metalView.drawableSize = CGSize(width: 1, height: 1)
        await view.configureDrawingForTesting(
            controller: controller,
            metalView: metalView,
            renderer: renderer
        )
        view.isOnscreenForTesting = true
        metalView.invalidationCount = 0
    }

    func draw() {
        view.draw(in: metalView)
    }

    func makeDrawable() throws -> CAMetalDrawable {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: Int(metalView.drawableSize.width),
            height: Int(metalView.drawableSize.height),
            mipmapped: false
        )
        descriptor.usage = .renderTarget
        let texture = try XCTUnwrap(metalView.device?.makeTexture(descriptor: descriptor))
        return RedrawDrawable(texture: texture)
    }
}

@MainActor
private final class RedrawMetalView: RiveUIView.MetalView {
    var drawable: CAMetalDrawable?
    var acquisitionCount = 0
    var invalidationCount = 0

    override var currentDrawable: CAMetalDrawable? {
        acquisitionCount += 1
        return drawable
    }

    // Record native invalidation without asking the window system to draw.
    #if !os(macOS) || RIVE_MAC_CATALYST
    override func setNeedsDisplay() {
        invalidationCount += 1
    }
    #else
    override var needsDisplay: Bool {
        get { false }
        set { if newValue { invalidationCount += 1 } }
    }
    #endif
}

private final class RedrawDrawable: NSObject, CAMetalDrawable {
    let texture: MTLTexture

    init(texture: MTLTexture) {
        self.texture = texture
        super.init()
    }

    var layer: CAMetalLayer { fatalError("This test does not present a drawable") }
    var presentedTime: CFTimeInterval { 0 }
    var drawableID: Int { 0 }
    func addPresentedHandler(_ block: @escaping MTLDrawablePresentedHandler) {}
    func present() {}
    func present(at presentationTime: CFTimeInterval) {}
    func present(afterMinimumDuration duration: CFTimeInterval) {}
}

@MainActor
private final class RedrawReplacementDelegate: RiveUIViewDelegate {
    var replacement: Rive?

    func view(_ view: RiveUIView, didReceiveError error: RiveUIViewError) {
        if case .noDrawable = error {
            view.rive = replacement
        }
    }
}

private final class RedrawRenderer: NSObject, RiveUIRendererProtocol {
    private(set) var configurations: [RiveUIRendererConfiguration] = []

    func draw(
        _ configuration: RiveUIRendererConfiguration,
        to texture: MTLTexture,
        from device: MTLDevice,
        onDraw: @escaping (MTLCommandBuffer) -> Void,
        onSkipped: (() -> Void)?,
        onError: ((Error) -> Void)?
    ) {
        MainActor.preconditionIsolated()
        configurations.append(configuration)
        // Dropping onDraw models a submission without performing GPU work.
    }

    func draw(
        _ configuration: RiveUIRendererConfiguration,
        to texture: MTLTexture,
        from device: MTLDevice,
        finalize: ((MTLCommandBuffer) -> Void)?,
        onSkipped: (() -> Void)?,
        onError: ((Error) -> Void)?
    ) {
        XCTFail("The view must use the onDraw renderer entry point")
    }
}
