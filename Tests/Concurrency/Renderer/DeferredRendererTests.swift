//
//  DeferredRendererTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if RIVE_CANVAS

import Metal
import XCTest
@testable import RiveRuntime

final class DeferredRendererTests: XCTestCase {
    private enum ExpectedOutcome {
        case completed
        case skipped
        case error(RendererError)
    }

    @MainActor
    func test_makeRenderer_returnsDeferredRenderer() async throws {
        let device = try await makeDevice()
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(worker: worker)

        XCTAssertTrue(rive.makeRenderer() is _RiveUIDeferredRenderer)
    }

    @MainActor
    func test_invalidSize_reportsError() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let renderer = worker.makeRenderer()
        await draw(
            with: renderer,
            configuration: RiveUIRendererConfiguration(
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
            expecting: .error(.invalidSize)
        )
    }

    @MainActor
    func test_nullArtboard_reportsOneError() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )

        await draw(
            with: worker.makeRenderer(),
            configuration: RiveUIRendererConfiguration(
                artboardHandle: 0,
                stateMachineHandle: .max,
                fit: .contain,
                alignment: .center,
                size: CGSize(width: texture.width, height: texture.height),
                pixelFormat: texture.pixelFormat,
                layoutScale: 1,
                color: 0
            ),
            to: texture,
            from: device,
            expecting: .error(.invalidArtboard)
        )
    }

    @MainActor
    func test_nullStateMachine_reportsOneError() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(worker: worker)
        var configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )
        configuration.stateMachineHandle = 0

        await draw(
            with: rive.makeRenderer(),
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .error(.invalidStateMachine)
        )
    }

    @MainActor
    func test_resize_completesChangedTarget() async throws {
        let device = try await makeDevice()
        let firstTexture = try makeTexture(device: device)
        let resizedTexture = try makeTexture(
            device: device,
            width: 96,
            height: 80
        )
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(worker: worker)
        let renderer = rive.makeRenderer()

        await draw(
            with: renderer,
            configuration: RiveUIRendererConfiguration(
                rive: rive,
                drawableSize: CGSize(
                    width: firstTexture.width,
                    height: firstTexture.height
                )
            ),
            to: firstTexture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: renderer,
            configuration: RiveUIRendererConfiguration(
                rive: rive,
                drawableSize: CGSize(
                    width: resizedTexture.width,
                    height: resizedTexture.height
                )
            ),
            to: resizedTexture,
            from: device,
            expecting: .completed
        )
    }

    @MainActor
    func test_multipleRenderersOnOneWorker_completeIndependently() async throws {
        let device = try await makeDevice()
        let firstTexture = try makeTexture(device: device)
        let secondTexture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(worker: worker)
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(
                width: firstTexture.width,
                height: firstTexture.height
            )
        )

        await draw(
            with: rive.makeRenderer(),
            configuration: configuration,
            to: firstTexture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: rive.makeRenderer(),
            configuration: configuration,
            to: secondTexture,
            from: device,
            expecting: .completed
        )
    }

    @MainActor
    func test_twoFilesOnOneDeferredWorker_bothComplete() async throws {
        let device = try await makeDevice()
        let firstTexture = try makeTexture(device: device)
        let secondTexture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let firstRive = try await makeRive(worker: worker)
        let secondRive = try await makeRive(
            named: "data_binding_test",
            worker: worker
        )

        XCTAssertNotEqual(firstRive.file.fileHandle, secondRive.file.fileHandle)
        XCTAssertNotEqual(
            firstRive.artboard.artboardHandle,
            secondRive.artboard.artboardHandle
        )
        XCTAssertNotEqual(
            firstRive.stateMachine.stateMachineHandle,
            secondRive.stateMachine.stateMachineHandle
        )

        await draw(
            with: firstRive.makeRenderer(),
            configuration: RiveUIRendererConfiguration(
                rive: firstRive,
                drawableSize: CGSize(
                    width: firstTexture.width,
                    height: firstTexture.height
                )
            ),
            to: firstTexture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: secondRive.makeRenderer(),
            configuration: RiveUIRendererConfiguration(
                rive: secondRive,
                drawableSize: CGSize(
                    width: secondTexture.width,
                    height: secondTexture.height
                )
            ),
            to: secondTexture,
            from: device,
            expecting: .completed
        )
    }

    @MainActor
    func test_deferredWorkers_renderWithDistinctContexts() async throws {
        let device = try await makeDevice()
        let firstWorker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let secondWorker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let firstContext = firstWorker.dependencies.workerService.dependencies
            .renderingMode.renderContext as AnyObject
        let secondContext = secondWorker.dependencies.workerService.dependencies
            .renderingMode.renderContext as AnyObject
        XCTAssertFalse(firstContext === secondContext)

        let firstRive = try await makeRive(worker: firstWorker)
        let secondRive = try await makeRive(worker: secondWorker)
        let firstTexture = try makeTexture(device: device)
        let secondTexture = try makeTexture(device: device)

        await draw(
            with: firstRive.makeRenderer(),
            configuration: RiveUIRendererConfiguration(
                rive: firstRive,
                drawableSize: CGSize(
                    width: firstTexture.width,
                    height: firstTexture.height
                )
            ),
            to: firstTexture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: secondRive.makeRenderer(),
            configuration: RiveUIRendererConfiguration(
                rive: secondRive,
                drawableSize: CGSize(
                    width: secondTexture.width,
                    height: secondTexture.height
                )
            ),
            to: secondTexture,
            from: device,
            expecting: .completed
        )
    }

    @MainActor
    func test_draw_completesConfigurationChangeThenSkipsUnchangedFrame() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(worker: worker)
        let renderer = rive.makeRenderer()
        var configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )

        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .completed
        )
        configuration.color = 0xFF_FF_00_00
        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .skipped
        )
    }

    @MainActor
    func test_advance_completesUnchangedConfiguration() async throws {
        let device = try await makeDevice()
        let texture = try makeTexture(device: device)
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let rive = try await makeRive(named: "marty", worker: worker)
        let renderer = rive.makeRenderer()
        let configuration = RiveUIRendererConfiguration(
            rive: rive,
            drawableSize: CGSize(width: texture.width, height: texture.height)
        )

        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .completed
        )
        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .skipped
        )

        rive.stateMachine.advance(by: 1 / 60)

        await draw(
            with: renderer,
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .completed
        )
    }

    @MainActor
    private func makeRive(
        named resourceName: String = "defaultstatemachine",
        worker: Worker
    ) async throws -> Rive {
        let file = try await File(
            source: .local(resourceName, Bundle(for: Self.self)),
            worker: worker
        )
        return try await Rive(file: file, dataBind: .none)
    }

    @MainActor
    private func makeDevice() async throws -> any MTLDevice {
        let device = await MetalDevice.shared.defaultDevice()
        return try XCTUnwrap(device?.value)
    }

    private func makeTexture(
        device: any MTLDevice,
        width: Int = 64,
        height: Int = 64
    ) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        return try XCTUnwrap(device.makeTexture(descriptor: descriptor))
    }

    @MainActor
    private func draw(
        with renderer: any RiveUIRendererProtocol,
        configuration: RiveUIRendererConfiguration,
        to texture: any MTLTexture,
        from device: any MTLDevice,
        expecting expectedOutcome: ExpectedOutcome,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let terminalOutcome = expectation(description: "Terminal outcome")
        terminalOutcome.assertForOverFulfill = true

        renderer.draw(
            configuration,
            to: texture,
            from: device,
            onDraw: { commandBuffer in
                guard case .completed = expectedOutcome else {
                    XCTFail(
                        "Expected \(expectedOutcome), received draw",
                        file: file,
                        line: line
                    )
                    terminalOutcome.fulfill()
                    return
                }
                commandBuffer.addCompletedHandler { completedBuffer in
                    XCTAssertEqual(
                        completedBuffer.status,
                        .completed,
                        file: file,
                        line: line
                    )
                    terminalOutcome.fulfill()
                }
            },
            onSkipped: {
                guard case .skipped = expectedOutcome else {
                    XCTFail(
                        "Expected \(expectedOutcome), received skip",
                        file: file,
                        line: line
                    )
                    terminalOutcome.fulfill()
                    return
                }
                terminalOutcome.fulfill()
            },
            onError: { error in
                guard case let .error(expectedError) = expectedOutcome else {
                    XCTFail(
                        "Expected \(expectedOutcome), received error: \(error)",
                        file: file,
                        line: line
                    )
                    terminalOutcome.fulfill()
                    return
                }
                XCTAssertEqual(
                    (error as NSError).code,
                    expectedError.rawValue,
                    file: file,
                    line: line
                )
                terminalOutcome.fulfill()
            }
        )

        await fulfillment(of: [terminalOutcome], timeout: 2)
    }
}

#endif
