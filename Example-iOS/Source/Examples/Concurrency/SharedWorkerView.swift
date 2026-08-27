//
//  SharedWorkerView.swift
//  RiveExample
//
//  Created by David Skuza on 3/4/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SharedWorkerView: View {
    var body: some View {
        ScrollView {
            ForEach(0..<4) { _ in
                AsyncRiveUIViewRepresentable {
                    let worker = try await Worker.shared()
                    let file = try await File(source: .local("marty_v2", .main), worker: worker)
                    return try await Rive(file: file)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
            }
        }
    }
}
