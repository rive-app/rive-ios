//
//  RiveLogger+StateMachine.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerStateMachineEvent {
    case advance(Double)
    case eventReceived(RiveEvent)
    case error(String)
    case instanceBind(String)
}

extension RiveLogger {
    private static let stateMachine = Logger(subsystem: subsystem, category: "rive-state-machine")

    @objc(logStateMachine:advance:) static func log(stateMachine: RiveStateMachineInstance, advance: Double) {
        log(stateMachine: stateMachine, event: .advance(advance))
    }

    @objc(logStateMachine:error:) static func log(stateMachine: RiveStateMachineInstance, error: String) {
        log(stateMachine: stateMachine, event: .error(error))
    }

    @objc(logStateMachine:instanceBind:) static func log(stateMachine: RiveStateMachineInstance, instanceBind name: String) {
        log(stateMachine: stateMachine, event: .instanceBind(name))
    }

    static func log(stateMachine: RiveStateMachineInstance, event: RiveLoggerStateMachineEvent) {
        switch event {
        case .advance(let elapsed):
            guard isVerbose else { return }
            _log(event: event, level: .debug) {
                Self.stateMachine.debug("\(self.prefix(for: stateMachine))Advancing by \(elapsed)s")
            }
        case .eventReceived(let receivedEvent):
            _log(event: event, level: .debug) {
                Self.stateMachine.debug("\(self.prefix(for: stateMachine))Received event \(receivedEvent.name())")
            }
        case .error(let error):
            _log(event: event, level: .error) {
                Self.stateMachine.error("\(error)")
            }
        case .instanceBind(let name):
            _log(event: event, level: .debug) {
                Self.stateMachine.debug("\(self.prefix(for: stateMachine))Bound view model instance \(name)")
            }
        }
    }

    private static func _log(event: RiveLoggerStateMachineEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.stateMachine),
              levels.contains(level)
        else { return }

        log()
    }

    private static func prefix(for stateMachine: RiveStateMachineInstance) -> String {
        return "\(stateMachine.name()): "
    }
}
