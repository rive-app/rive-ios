//
//  Renderer+Worker.swift
//  RiveRuntime
//
//  Created by Cursor Assistant on 4/6/26.
//

import Foundation

@_spi(RiveExperimental)
public extension RiveUIRenderer {
    /// Creates a renderer backed by the given worker's rendering pipeline.
    @MainActor
    convenience init(worker: Worker) {
        self.init(
            commandQueue: worker.dependencies.workerService.dependencies.commandQueue,
            renderContext: worker.dependencies.workerService.dependencies.renderContext
        )
    }

    /// Creates a renderer from the worker that backs the given Rive instance.
    @MainActor
    convenience init(rive: Rive) {
        self.init(worker: rive.file.worker)
    }
}
