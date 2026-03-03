//
//  PlayerView.swift
//  RiveExample
//
//  Created by David Skuza on 2/23/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

struct PlayerView: View {
    @State private var selectedFPS = 60
    @State private var isPaused = true

    var body: some View {
        Group {
            VStack {
                AsyncRiveUIViewRepresentable {
                    let worker = try await Worker()
                    let file = try await File(source: .local("marty_v2", .main), worker: worker)
                    let rive = try await Rive(file: file)
                    return rive
                }
                .frameRate(.fps(selectedFPS))
                .paused(isPaused)

                Form {
                    Picker("Frame Rate", selection: $selectedFPS) {
                        Text("15fps").tag(15)
                        Text("30fps").tag(30)
                        Text("60fps").tag(60)
                        Text("120fps").tag(120)
                    }

                    Button(isPaused ? "Play" : "Pause") {
                        isPaused.toggle()
                    }
                }
            }
        }
    }
}
