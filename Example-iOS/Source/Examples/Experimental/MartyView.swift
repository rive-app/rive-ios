//
//  ExperimentalMarty.swift
//  RiveExample
//
//  Created by David Skuza on 12/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

struct MartyView: View {
    var body: some View {
        RiveUIView(rive: {
            let worker = Worker()
            let file = try await File(source: .local("marty_v2", Bundle.main), worker: worker)
            return try await Rive(file: file)
        }).view()
    }
}
