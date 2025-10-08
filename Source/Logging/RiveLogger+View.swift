//
//  RiveLogger+View.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerViewEvent {
    case touchBegan(CGPoint, Int32)
    case touchMoved(CGPoint, Int32)
    case touchEnded(CGPoint, Int32)
    case touchCancelled(CGPoint, Int32)
    case touchExited(CGPoint, Int32)
    case play
    case pause
    case stop
    case reset
    case advance(Double)
    case eventReceived(String)
    case drawing(CGSize)
    case error(String)
}

extension RiveLogger {
    private static let view = Logger(subsystem: subsystem, category: "rive-view")

    static func log(view: RiveView, event: RiveLoggerViewEvent) {
        switch event {
        case .touchBegan(let point, let id):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Touch (id: \(id)) began at {\(point.x),\(point.y)}")
            }
        case .touchMoved(let point, let id):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Touch (id: \(id)) moved to {\(point.x),\(point.y)}")
            }
        case .touchEnded(let point, let id):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Touch (id: \(id)) ended at {\(point.x),\(point.y)}")
            }
        case .touchCancelled(let point, let id):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Touch (id: \(id)) cancelled at {\(point.x),\(point.y)}")
            }
        case .touchExited(let point, let id):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Touch (id: \(id)) exited at {\(point.x),\(point.y)}")
            }
        case .play:
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Playing")
            }
        case .pause:
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Paused")
            }
        case .stop:
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Stopped")
            }
        case .reset:
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Reset")
            }
        case .advance(let elapsed):
            guard isVerbose else { return }
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Advancing by \(elapsed)s")
            }
        case .eventReceived(let name):
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Received event \(name)")
            }
        case .drawing(let size):
            guard isVerbose else { return }
            _log(event: event, level: .debug) {
                Self.view.debug("\(self.prefix(for: view))Drawing size {\(size.width),\(size.height)}")
            }
        case .error(let message):
            _log(event: event, level: .error) {
                Self.view.error("\(self.prefix(for: view))\(message)")
            }
        }
    }

    private static func _log(event: RiveLoggerViewEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.view),
              levels.contains(level)
        else { return }

        log()
    }

    private static func prefix(for view: RiveView) -> String {
        if let stateMachine = view.riveModel?.stateMachine {
            return "[\(stateMachine.name())]: "
        } else if let animation = view.riveModel?.animation {
            return "[\(animation.name())]: "
        } else {
            return ""
        }
    }
}

