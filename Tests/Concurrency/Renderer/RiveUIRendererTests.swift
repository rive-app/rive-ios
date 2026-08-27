//
//  RiveUIRendererTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

import Metal
import XCTest
@testable import RiveRuntime

final class RiveUIRendererTests: XCTestCase {
    @MainActor
    func test_makeRenderer_returnsImmediateRenderer() async throws {
        let device = try await makeDevice()
        let worker = Worker(device: device)
        let file = try await File(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file, dataBind: .none)

        XCTAssertTrue(rive.makeRenderer() is RiveUIRenderer)
    }

    @MainActor
    func test_invalidSize_reportsErrorWithoutQueuingDraw() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let commandQueue = MockCommandQueue()
        let renderer = RiveUIRenderer(
            commandQueue: commandQueue,
            renderContext: RiveUIRenderContext(device: device)
        )
        var receivedError: NSError?

        renderer.draw(
            RiveUIRendererConfiguration(
                artboardHandle: 0,
                stateMachineHandle: 0,
                fit: .contain,
                alignment: .center,
                size: .zero,
                pixelFormat: texture.pixelFormat,
                layoutScale: 1,
                color: 0
            ),
            to: texture,
            from: device,
            onDraw: { _ in
                XCTFail("Invalid size should not draw")
            },
            onSkipped: {
                XCTFail("Invalid size should not skip")
            },
            onError: { error in
                receivedError = error as NSError
            }
        )

        XCTAssertEqual(receivedError?.code, RendererError.invalidSize.rawValue)
        XCTAssertTrue(commandQueue.drawCalls.isEmpty)
    }

    @MainActor
    func test_invalidTexture_reportsErrorWithoutQueuingDraw() async throws {
        let device = try await makeDevice()
        let commandQueue = MockCommandQueue()
        let renderer = RiveUIRenderer(
            commandQueue: commandQueue,
            renderContext: RiveUIRenderContext(device: device)
        )
        let configuration = RiveUIRendererConfiguration(
            artboardHandle: 0,
            stateMachineHandle: 0,
            fit: .contain,
            alignment: .center,
            size: CGSize(width: 1, height: 1),
            pixelFormat: .bgra8Unorm,
            layoutScale: 1,
            color: 0
        )
        let invalidTextures: [(String, any MTLTexture)] = [
            (
                "dimensions",
                try makeTexture(device: device, width: 2)
            ),
            (
                "pixel format",
                try makeTexture(device: device, pixelFormat: .rgba8Unorm)
            ),
            (
                "usage",
                try makeTexture(device: device, usage: .shaderRead)
            ),
        ]

        for (mismatch, texture) in invalidTextures {
            var receivedError: NSError?
            renderer.draw(
                configuration,
                to: texture,
                from: device,
                onDraw: { _ in
                    XCTFail("Invalid texture \(mismatch) should not draw")
                },
                onSkipped: {
                    XCTFail("Invalid texture \(mismatch) should not skip")
                },
                onError: { error in
                    receivedError = error as NSError
                }
            )

            XCTAssertEqual(
                receivedError?.code,
                RendererError.invalidTexture.rawValue
            )
        }

        XCTAssertTrue(commandQueue.drawCalls.isEmpty)
    }

    #if RIVE_CANVAS
    @MainActor
    func test_disabledRenderer_reportsInitializationError() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let expectedError = NSError(
            domain: "app.rive.renderer",
            code: RendererError.invalidRenderer.rawValue,
            userInfo: nil
        )
        let renderer = RiveUIRenderer(rendererError: expectedError)
        var receivedError: NSError?

        renderer.draw(
            RiveUIRendererConfiguration(
                artboardHandle: 0,
                stateMachineHandle: 0,
                fit: .contain,
                alignment: .center,
                size: .zero,
                pixelFormat: texture.pixelFormat,
                layoutScale: 1,
                color: 0
            ),
            to: texture,
            from: device,
            onDraw: { _ in
                XCTFail("A disabled renderer should not draw")
            },
            onSkipped: {
                XCTFail("A disabled renderer should not skip")
            },
            onError: { error in
                receivedError = error as NSError
            }
        )

        XCTAssertTrue(receivedError === expectedError)
    }
    #endif

    @MainActor
    func test_draw_completesThenSkipsUnchangedFrame() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(device: device)
        let file = try await File(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file, dataBind: .none)
        let renderer = rive.makeRenderer()
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )

        let completed = expectation(description: "Completed frame")
        renderer.draw(
            configuration,
            to: texture,
            from: device,
            onDraw: { commandBuffer in
                commandBuffer.addCompletedHandler { completedBuffer in
                    XCTAssertEqual(completedBuffer.status, .completed)
                    completed.fulfill()
                }
            },
            onSkipped: {
                XCTFail("Changed frame should not skip")
                completed.fulfill()
            },
            onError: { error in
                XCTFail("Changed frame failed: \(error)")
                completed.fulfill()
            }
        )
        await fulfillment(of: [completed], timeout: 2)

        let skipped = expectation(description: "Skipped frame")
        renderer.draw(
            configuration,
            to: texture,
            from: device,
            onDraw: { commandBuffer in
                XCTFail("Unchanged frame should not draw")
                skipped.fulfill()
            },
            onSkipped: {
                skipped.fulfill()
            },
            onError: { error in
                XCTFail("Unchanged frame failed: \(error)")
                skipped.fulfill()
            }
        )
        await fulfillment(of: [skipped], timeout: 2)
    }

    @MainActor
    func test_draw_recreatesTargetWhenPixelFormatChanges() async throws {
        let device = try await makeDevice()
        let firstTexture = try makeTexture(
            device: device,
            pixelFormat: .bgra8Unorm
        )
        let secondTexture = try makeTexture(
            device: device,
            pixelFormat: .rgba8Unorm
        )
        let worker = Worker(device: device)
        let file = try await File(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file, dataBind: .none)
        let renderer = rive.makeRenderer()
        var configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(
                width: firstTexture.width,
                height: firstTexture.height
            )
        )
        configuration.pixelFormat = firstTexture.pixelFormat

        await draw(
            with: renderer,
            configuration: configuration,
            to: firstTexture,
            from: device
        )

        configuration.pixelFormat = secondTexture.pixelFormat
        await draw(
            with: renderer,
            configuration: configuration,
            to: secondTexture,
            from: device
        )
    }

    @MainActor
    func test_trailingClosureThatCommits_remainsCompatible() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(device: device)
        let file = try await File(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file, dataBind: .none)
        let renderer = rive.makeRenderer()
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )
        let completed = expectation(description: "Completed legacy draw")

        renderer.draw(configuration, to: texture, from: device) { commandBuffer in
            commandBuffer.addCompletedHandler { completedBuffer in
                XCTAssertEqual(completedBuffer.status, .completed)
                completed.fulfill()
            }
            commandBuffer.commit()
        } onSkipped: {
            XCTFail("Changed frame should not skip")
            completed.fulfill()
        } onError: { error in
            XCTFail("Changed frame failed: \(error)")
            completed.fulfill()
        }

        await fulfillment(of: [completed], timeout: 2)
    }

    @MainActor
    func test_finalizeBlock_commitsCommandBuffer() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(device: device)
        let file = try await File(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            worker: worker
        )
        let rive = try await Rive(file: file, dataBind: .none)
        let renderer = rive.makeRenderer()
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )
        let completed = expectation(description: "Completed legacy draw")

        renderer.draw(
            configuration,
            to: texture,
            from: device,
            finalize: { commandBuffer in
                commandBuffer.addCompletedHandler { completedBuffer in
                    XCTAssertEqual(completedBuffer.status, .completed)
                    completed.fulfill()
                }
                commandBuffer.commit()
            },
            onSkipped: {
                XCTFail("Changed frame should not skip")
                completed.fulfill()
            },
            onError: { error in
                XCTFail("Changed frame failed: \(error)")
                completed.fulfill()
            }
        )

        await fulfillment(of: [completed], timeout: 2)
    }

    @MainActor
    private func makeDevice() async throws -> any MTLDevice {
        let device = await MetalDevice.shared.defaultDevice()
        return try XCTUnwrap(device?.value)
    }

    private func makeTexture(
        device: any MTLDevice,
        width: Int = 1,
        height: Int = 1,
        pixelFormat: MTLPixelFormat = MTLRiveColorPixelFormat(),
        usage: MTLTextureUsage = .renderTarget
    ) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = usage
        return try XCTUnwrap(device.makeTexture(descriptor: descriptor))
    }

    @MainActor
    private func draw(
        with renderer: any RiveUIRendererProtocol,
        configuration: RiveUIRendererConfiguration,
        to texture: any MTLTexture,
        from device: any MTLDevice,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let completed = expectation(description: "Completed frame")
        renderer.draw(
            configuration,
            to: texture,
            from: device,
            onDraw: { commandBuffer in
                commandBuffer.addCompletedHandler { completedBuffer in
                    XCTAssertEqual(
                        completedBuffer.status,
                        .completed,
                        file: file,
                        line: line
                    )
                    completed.fulfill()
                }
            },
            onSkipped: {
                XCTFail("Frame should not skip", file: file, line: line)
                completed.fulfill()
            },
            onError: { error in
                XCTFail(
                    "Frame failed: \(error)",
                    file: file,
                    line: line
                )
                completed.fulfill()
            }
        )
        await fulfillment(of: [completed], timeout: 2)
    }
}
