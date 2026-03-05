//
//  SharedWorkerView.swift
//  RiveExample
//
//  Created by David Skuza on 3/4/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

actor WorkerCache {
    static let shared = WorkerCache()

    @MainActor
    private var cachedWorker: Worker?

    @MainActor
    func worker() async throws -> Worker {
        if let cachedWorker {
            return cachedWorker
        }

        let worker = try await Worker()
        cachedWorker = worker
        return worker
    }
}

struct SharedWorkerView: View {
    var body: some View {
        ScrollView {
            ForEach(0..<4) { _ in
                AsyncRiveUIViewRepresentable {
                    let worker = try await WorkerCache.shared.worker()
                    let file = try await File(source: .local("marty_v2", .main), worker: worker)
                    return try await Rive(file: file)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
            }
        }
    }
}
