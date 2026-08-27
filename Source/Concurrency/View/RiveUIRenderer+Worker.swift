//
//  RiveUIRenderer+Worker.swift
//  RiveRuntime
//
//  Created by Cursor Assistant on 4/6/26.
//

import Foundation

public extension RiveUIRenderer {
    /// Creates an immediate renderer for a worker using immediate rendering.
    ///
    /// This deprecated initializer cannot create a deferred renderer. When
    /// passed a deferred worker, debug builds assert and optimized builds
    /// return a disabled renderer that reports an error from draw calls. Use
    /// ``Rive/makeRenderer()`` to select the worker's renderer implementation.
    @available(
        *,
        deprecated,
        message: "Create a Rive with this worker, then call rive.makeRenderer()."
    )
    @MainActor
    convenience init(worker: Worker) {
        let dependencies = worker.dependencies.workerService.dependencies
        switch dependencies.renderingMode {
        case .immediate(let renderContext):
            self.init(
                commandQueue: dependencies.commandQueue,
                renderContext: renderContext
            )
        #if RIVE_CANVAS
        case .deferred:
            let message =
                "RiveUIRenderer(worker:) does not support deferred rendering. Create a Rive with this worker, then call rive.makeRenderer()."
            assertionFailure(message)
            RiveLog.error(tag: .worker, message)
            self.init(
                rendererError: NSError(
                    domain: "app.rive.renderer",
                    code: RendererError.invalidRenderer.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )
        #endif
        }
    }

    /// Creates an immediate renderer from the worker backing the given Rive.
    ///
    /// This has the same immediate-only behavior as ``init(worker:)``. Use
    /// ``Rive/makeRenderer()`` to select the worker's renderer implementation.
    @available(
        *,
        deprecated,
        message: "Use rive.makeRenderer()."
    )
    @MainActor
    convenience init(rive: Rive) {
        self.init(worker: rive.file.worker)
    }
}

public extension Rive {
    /// Creates a renderer matching the rendering mode selected when this
    /// instance's worker was created.
    ///
    /// Retain and reuse the returned renderer for a single output surface.
    /// It may draw configurations from any `Rive` backed by the same worker;
    /// keep each source instance alive while drawing its configurations. Target
    /// textures must be created by that worker's Metal device.
    @MainActor
    func makeRenderer() -> any RiveUIRendererProtocol {
        file.worker.makeRenderer()
    }
}
