// Copyright © 2026 Rive. All rights reserved.

#if RIVE_CANVAS

import Metal
import XCTest
@testable import RiveRuntime

final class RiveUIRendererRecordingTests: XCTestCase {
    @MainActor
    func test_advanceAndPendingWork_drawAgainWithUnchangedConfiguration() async throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let context = RecordingRenderContext(device: device)
        let queue = CommandQueue()
        let server = CommandServer(commandQueue: queue, renderContext: context)
        let service = WorkerService(dependencies: .init(
            commandQueue: queue,
            commandServer: server,
            renderContext: context,
            messagePumpDriver: queue
        ))
        let worker = Worker(dependencies: .init(workerService: service))
        let file = try await File(
            source: .local("marty", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file)
        let renderer = rive.makeRenderer()
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: 64,
            height: 64,
            mipmapped: false
        )
        descriptor.usage = .renderTarget
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )

        // Apply the initial animation state before drawing its first frame.
        rive.stateMachine.advance(by: 0)
        await draw(expectingDraw: true)
        await draw(expectingDraw: false)
        rive.stateMachine.advance(by: 1.0 / 60.0)
        await draw(expectingDraw: true)
        await draw(expectingDraw: false)

        // Loading another file records resource work without changing this artboard.
        context.checksPendingWork = true
        let anotherFile = try await File(
            source: .local("marty", Bundle(for: Self.self)),
            worker: worker
        )
        await draw(expectingDraw: true)
        await draw(expectingDraw: false)
        withExtendedLifetime(anotherFile) {}

        func draw(
            expectingDraw: Bool,
            file: StaticString = #filePath,
            line: UInt = #line
        ) async {
            let outcome = expectation(description: expectingDraw ? "Draw" : "Skip")
            outcome.assertForOverFulfill = true
            renderer.draw(
                configuration,
                to: texture,
                from: device,
                onDraw: { _ in
                    XCTAssertTrue(expectingDraw, "Unexpected draw", file: file, line: line)
                    outcome.fulfill()
                },
                onSkipped: {
                    XCTAssertFalse(expectingDraw, "Unexpected skip", file: file, line: line)
                    outcome.fulfill()
                },
                onError: { error in
                    XCTFail("Unexpected renderer error: \(error)", file: file, line: line)
                    outcome.fulfill()
                }
            )
            // Observe the scheduling decision without waiting for GPU completion.
            await fulfillment(of: [outcome], timeout: 2)
        }
    }

    @MainActor
    func test_configurationChanges_drawAgainThenSkip() async throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let context = RecordingRenderContext(device: device)
        context.checksPendingWork = false
        let queue = CommandQueue()
        let server = CommandServer(commandQueue: queue, renderContext: context)
        let service = WorkerService(dependencies: .init(
            commandQueue: queue,
            commandServer: server,
            renderContext: context,
            messagePumpDriver: queue
        ))
        let worker = Worker(dependencies: .init(workerService: service))
        let file = try await File(
            source: .local("marty", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file)
        let renderer = rive.makeRenderer()
        var configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: 64, height: 64)
        )
        configuration.pixelFormat = .bgra8Unorm
        rive.stateMachine.advance(by: 0)

        try await drawThenSkip()
        configuration.color = 0xFFFF0000
        try await drawThenSkip()
        configuration.size = CGSize(width: 96, height: 80)
        try await drawThenSkip()
        configuration.pixelFormat = .rgba8Unorm
        try await drawThenSkip()

        func drawThenSkip(file: StaticString = #filePath, line: UInt = #line) async throws {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: configuration.pixelFormat,
                width: Int(configuration.size.width),
                height: Int(configuration.size.height),
                mipmapped: false
            )
            descriptor.usage = .renderTarget
            let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))

            for expectingDraw in [true, false] {
                let outcome = expectation(description: expectingDraw ? "Draw" : "Skip")
                outcome.assertForOverFulfill = true
                renderer.draw(
                    configuration,
                    to: texture,
                    from: device,
                    onDraw: { _ in
                        XCTAssertTrue(expectingDraw, "Unexpected draw", file: file, line: line)
                        outcome.fulfill()
                    },
                    onSkipped: {
                        XCTAssertFalse(expectingDraw, "Unexpected skip", file: file, line: line)
                        outcome.fulfill()
                    },
                    onError: { error in
                        XCTFail("Unexpected renderer error: \(error)", file: file, line: line)
                        outcome.fulfill()
                    }
                )
                await fulfillment(of: [outcome], timeout: 2)
            }
        }
    }
}

#endif
