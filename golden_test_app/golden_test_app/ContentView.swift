//
//  ContentView.swift
//  golden_test_app
//
//  Created by Jonathon Copeland on 5/15/24.
//

import SwiftUI
import RiveRuntime

@MainActor
struct ContentView: View {
    @StateObject private var runner = GoldenTestRunner()

    var body: some View {
        RiveUIViewRepresentable(rive: runner.rive)
            .paused(true)
            .onAppear { runner.start() }
            .onDisappear { runner.cancel() }
    }
}
