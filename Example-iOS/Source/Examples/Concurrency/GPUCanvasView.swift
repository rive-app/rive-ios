//
//  GPUCanvasView.swift
//  RiveExample
//
//  Copyright © 2026 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

struct GPUCanvasView: View {
    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker.sharedGPUCanvas()
            let file = try await File(
                source: .local("ore", .main),
                worker: worker
            )
            return try await Rive(file: file)
        }
        .navigationTitle("GPU Canvas")
    }
}
