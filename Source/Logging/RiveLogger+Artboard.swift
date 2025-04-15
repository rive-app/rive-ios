//
//  RiveLogger+Artboard.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerArtboardEvent  {
    case advance(Double)
    case error(String)
    case instanceBind(String)
}

extension RiveLogger {
    private static let artboard = Logger(subsystem: subsystem, category: "rive-artboard")

    @objc(logArtboard:advance:) static func log(artboard: RiveArtboard, advance: Double) {
        log(artboard: artboard, event: .advance(advance))
    }

    @objc(logArtboard:error:) static func log(artboard: RiveArtboard, error: String) {
        log(artboard: artboard, event: .error(error))
    }

    @objc(logArtboard:instanceBind:) static func log(artboard: RiveArtboard, instanceBind name: String) {
        log(artboard: artboard, event: .instanceBind(name))
    }

    static func log(artboard: RiveArtboard, event: RiveLoggerArtboardEvent) {
        switch event {
        case .advance(let elapsed):
            guard isVerbose else { return }
            _log(event: event, level: .debug) {
                Self.artboard.debug("\(self.prefix(for: artboard))Advanced by \(elapsed)s")
            }
        case .error(let error):
            _log(event: event, level: .error) {
                Self.artboard.error("\(error)")
            }
        case .instanceBind(let name):
            _log(event: event, level: .debug) {
                Self.artboard.debug("\(self.prefix(for: artboard))Bound view model instance \(name)")
            }
        }
    }

    private static func _log(event: RiveLoggerArtboardEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.artboard),
              levels.contains(level)
        else { return }

        log()
    }

    private static func prefix(for artboard: RiveArtboard) -> String {
        return "\(artboard.name()): "
    }
}
