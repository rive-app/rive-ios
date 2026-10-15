//
//  QuickStartView.swift
//  RiveExample
//
//  Created by David Skuza on 1/12/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import SwiftUI
import RiveRuntime

private class QuickStartViewModel: ObservableObject {
    @Published private(set) var rive: Rive?
    private var viewModelInstance: ViewModelInstance?

    @Published private var healthValue: Float = 100 {
        didSet {
            Task { @MainActor in
                viewModelInstance?.setValue(of: NumberProperty(path: "health"), to: healthValue)
            }
        }
    }

    var health: Binding<Float> {
        return Binding {
            self.healthValue
        } set: { health in
            self.healthValue = health
        }
    }

    func reload() {
        Task { @MainActor in
            defer {
                health.wrappedValue = 100
            }

            do {
                let worker = try await Worker()
                let file = try await File(source: .local("quick_start", Bundle.main), worker: worker)
                let artboard = try await file.createArtboard()
                let stateMachine = try await artboard.createStateMachine()
                let instance = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
                try await stateMachine.bindViewModelInstances(main: instance)
                self.viewModelInstance = instance
                self.rive = try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)
            } catch {
                print(error)
            }
        }
    }

    @MainActor
    func triggerGameOver() {
        viewModelInstance?.fire(trigger: TriggerProperty(path: "gameOver"))
    }
}

struct QuickStartView: View {
    @StateObject private var viewModel = QuickStartViewModel()

    var body: some View {
        VStack {
            if let rive = viewModel.rive {
                RiveUIViewRepresentable(rive: rive)

                Form {
                    Button("Game Over") {
                        viewModel.triggerGameOver()
                    }

                    Slider(value: viewModel.health, in: 0...100)

                    Button("Reload", role: .destructive) {
                        viewModel.reload()
                    }
                }
            }
        }.task {
            viewModel.reload()
        }
    }
}
