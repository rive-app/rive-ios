//
//  AsyncShared+Worker.swift
//  RiveExample
//
//  Copyright © 2026 Rive. All rights reserved.
//

import RiveRuntime

extension AsyncShared where Value == Worker {
    convenience init(configuration: Worker.Configuration = .init()) {
        self.init {
            try await Worker(configuration: configuration)
        }
    }
}

extension Worker {
    @MainActor
    private static let sharedWorker = AsyncShared<Worker>()

    @MainActor
    private static let sharedGPUCanvasWorker = AsyncShared<Worker>(
        configuration: .init(enableGPUCanvas: true)
    )

    @MainActor
    static func shared() async throws -> Worker {
        try await sharedWorker.value()
    }

    @MainActor
    static func sharedGPUCanvas() async throws -> Worker {
        try await sharedGPUCanvasWorker.value()
    }
}
