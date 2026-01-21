//
//  ExperimentalHealthBarView.swift
//  RiveExample
//
//  Created by David Skuza on 1/12/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

private class QuickStartViewModel: ObservableObject {
    private let worker: Worker

    @Published private(set) var rive: Rive?

    @Published private var healthValue: Float = 100 {
        didSet {
            Task { @MainActor in
                rive?.viewModelInstance?.setValue(of: NumberProperty(path: "health"), to: healthValue)
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

    @MainActor
    init() {
        self.worker = Worker()
    }

    func reload() {
        Task { @MainActor in
            defer {
                health.wrappedValue = 100
            }

            do {
                let file = try await File(source: .local("quick_start", Bundle.main), worker: worker)
                self.rive = try await Rive(file: file)
            } catch {
                print(error)
            }
        }
    }

    @MainActor
    func triggerGameOver() {
        guard let rive else {
            return
        }

        rive.viewModelInstance?.fire(trigger: TriggerProperty(path: "gameOver"))
    }
}

struct QuickStartView: View {
    @StateObject private var viewModel = QuickStartViewModel()

    var body: some View {
        VStack {
            if let rive = viewModel.rive {
                RiveUIView(rive: rive).view()

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
