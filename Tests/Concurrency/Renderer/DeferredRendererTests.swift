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
        await assertDrawError(
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
            expecting: .invalidSize
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

        await assertDrawError(
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
            expecting: .invalidArtboard
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

        await assertDrawError(
            with: rive.makeRenderer(),
            configuration: configuration,
            to: texture,
            from: device,
            expecting: .invalidStateMachine
        )
    }

    @MainActor
    func test_multipleRenderersOnOneWorker_haveDistinctIdentities() async throws {
        let device = try await makeDevice()
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let firstRenderer = worker.makeRenderer()
        let secondRenderer = worker.makeRenderer()

        XCTAssertFalse(firstRenderer === secondRenderer)
    }

    @MainActor
    func test_twoFilesOnOneDeferredWorker_haveDistinctHandles() async throws {
        let device = try await makeDevice()
        let worker = Worker(
            device: device,
            configuration: .init(enableGPUCanvas: true)
        )
        let firstRive = try await makeRive(worker: worker)
        let secondRive = try await makeRive(
            named: "data_binding_test",
            worker: worker
        )

        XCTAssertTrue(firstRive.file.worker === worker)
        XCTAssertTrue(secondRive.file.worker === worker)
        XCTAssertNotEqual(firstRive.file.fileHandle, secondRive.file.fileHandle)
        XCTAssertNotEqual(
            firstRive.artboard.artboardHandle,
            secondRive.artboard.artboardHandle
        )
        XCTAssertNotEqual(
            firstRive.stateMachine.stateMachineHandle,
            secondRive.stateMachine.stateMachineHandle
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

    private func makeTexture(device: any MTLDevice) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: 64,
            height: 64,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        return try XCTUnwrap(device.makeTexture(descriptor: descriptor))
    }

    @MainActor
    private func assertDrawError(
        with renderer: any RiveUIRendererProtocol,
        configuration: RiveUIRendererConfiguration,
        to texture: any MTLTexture,
        from device: any MTLDevice,
        expecting expectedError: RendererError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let outcome = expectation(description: "Renderer error")
        outcome.assertForOverFulfill = true

        renderer.draw(
            configuration,
            to: texture,
            from: device,
            onDraw: { _ in
                XCTFail("Invalid configuration should not draw", file: file, line: line)
                outcome.fulfill()
            },
            onSkipped: {
                XCTFail("Invalid configuration should not skip", file: file, line: line)
                outcome.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    (error as NSError).code,
                    expectedError.rawValue,
                    file: file,
                    line: line
                )
                outcome.fulfill()
            }
        )

        await fulfillment(of: [outcome], timeout: 2)
    }
}

#endif
