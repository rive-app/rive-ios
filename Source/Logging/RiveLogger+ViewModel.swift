//
//  RiveLogger+ViewModel.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerViewModelEvent {
    case booleanInput(String, String?, Bool)
    case floatInput(String, String?, Float)
    case doubleInput(String, String?, Double)
    case triggerInput(String, String?)
    case textRun(String, String?, String)
    case error(String)
    case fatalError(String)
    case play
    case pause
    case stop
    case reset
}

extension RiveLogger {
    private static let viewModel = Logger(subsystem: subsystem, category: "rive-view-model")

    static func log(viewModel: RiveViewModel, event: RiveLoggerViewModelEvent) {
        switch event {
        case .booleanInput(let name, let path, let value):
            _log(event: event, level: .debug) {
                let atPath = path != nil ? " at path \(path!) " : " "
                Self.viewModel.debug(
                    "\(self.prefix(for: viewModel))Input \(name)\(atPath)set to \(value)"
                )
            }
        case .floatInput(let name, let path, let value):
            _log(event: event, level: .debug) {
                let atPath = path != nil ? " at path \(path!) " : " "
                Self.viewModel.debug(
                    "\(self.prefix(for: viewModel))Input \(name)\(atPath)set to \(value)"
                )
            }
        case .doubleInput(let name, let path, let value):
            _log(event: event, level: .debug) {
                let atPath = path != nil ? " at path \(path!) " : " "
                Self.viewModel.debug(
                    "\(self.prefix(for: viewModel))Input \(name)\(atPath)set to \(value)"
                )
            }
        case .triggerInput(let name, let path):
            _log(event: event, level: .debug) {
                let atPath = path != nil ? " at path: \(path!) " : " "
                Self.viewModel.debug(
                    "\(self.prefix(for: viewModel))Input \(name)\(atPath) triggered"
                )
            }
        case .textRun(let name, let path, let value):
            _log(event: event, level: .debug) {
                let atPath = path != nil ? " at path \(path!) " : " "
                Self.viewModel.debug(
                    "\(self.prefix(for: viewModel))Text run \(name)\(atPath)set to \(value)"
                )
            }
        case .error(let message):
            _log(event: event, level: .error) {
                Self.viewModel.error("\(self.prefix(for: viewModel))\(message)")
            }
        case .fatalError(let message):
            _log(event: event, level: .fault) {
                Self.viewModel.fault("\(self.prefix(for: viewModel))\(message)")
            }
        case .play:
            _log(event: event, level: .debug) {
                Self.viewModel.debug("\(self.prefix(for: viewModel))Playing")
            }
        case .pause:
            _log(event: event, level: .debug) {
                Self.viewModel.debug("\(self.prefix(for: viewModel))Paused")
            }
        case .stop:
            _log(event: event, level: .debug) {
                Self.viewModel.debug("\(self.prefix(for: viewModel))Stopped")
            }
        case .reset:
            _log(event: event, level: .debug) {
                Self.viewModel.debug("\(self.prefix(for: viewModel))Reset")
            }
        }
    }

    static private func _log(event: RiveLoggerViewModelEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.viewModel),
              levels.contains(level)
        else { return }

        log()
    }

    private static func prefix(for viewModel: RiveViewModel) -> String {
        if let stateMachine = viewModel.riveModel?.stateMachine {
            return "[\(stateMachine.name())]: "
        } else if let animation = viewModel.riveModel?.animation {
            return "[\(animation.name())]: "
        } else {
            return ""
        }
    }
}
