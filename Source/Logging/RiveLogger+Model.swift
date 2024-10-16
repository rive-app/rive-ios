//
//  RiveLogger+Model.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerModelEvent {
    case volume(Float)
    case artboardByName(String)
    case artboardByIndex(Int)
    case defaultArtboard
    case error(String)
    case stateMachineByName(String)
    case stateMachineByIndex(Int)
    case defaultStateMachine
    case animationByName(String)
    case animationByIndex(Int)
}

extension RiveLogger {
    private static let model = Logger(subsystem: subsystem, category: "rive-model")

    static func log(model: RiveModel, event: RiveLoggerModelEvent) {
        switch event {
        case .volume(let volume):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Volume set to \(volume)"
                )
            }
        case .artboardByName(let name):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Artboard set to artboard named \(name)"
                )
            }
        case .artboardByIndex(let index):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Artboard set to artboard at index \(index)"
                )
            }
        case .defaultArtboard:
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Artboard set to default artboard"
                )
            }
        case .error(let message):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))\(message)"
                )
            }
        case .stateMachineByName(let name):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))State machine set to state machine named \(name)"
                )

            }
        case .stateMachineByIndex(let index):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))State machine set to state machine at index \(index)"
                )
            }
        case .defaultStateMachine:
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))State machine set to default state machine"
                )
            }
        case .animationByName(let name):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Animation set to animation named \(name)"
                )
            }
        case .animationByIndex(let index):
            _log(event: event, level: .debug) {
                Self.model.debug(
                    "\(self.prefix(for: model))Animation set to animation at index \(index)"
                )
            }
        }
    }

    private static func _log(event: RiveLoggerModelEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.model),
              levels.contains(level)
        else { return }

        log()
    }

    private static func prefix(for model: RiveModel) -> String {
        if let stateMachine = model.stateMachine {
            return "[\(stateMachine.name())]: "
        } else if let animation = model.animation {
            return "[\(animation.name())]: "
        } else {
            return ""
        }
    }
}
