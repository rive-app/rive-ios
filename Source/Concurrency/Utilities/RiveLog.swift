//
//  RiveLog.swift
//  RiveRuntime
//
//  Created by David Skuza on 3/12/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import os

/// `RiveLog` forwards tagged, lazily-evaluated messages to the active `logger`.
/// Use `RiveLog.system(levels:)` for the built-in platform logger, or assign a
/// custom implementation to `RiveLog.logger`. Use `RiveLog.none` to disable
/// logging (the default).
public enum RiveLog: Sendable {
    private static let lock = NSLock()
    private static var _logger: any Logger = noneLogger
    
    private static let noneLogger: any Logger = NoOpLogger()
    nonisolated public static var none: any Logger { noneLogger }

    nonisolated public static func system(levels: Level = .default) -> any Logger {
        SystemLogger(levels: levels)
    }
    
    nonisolated public static var logger: any Logger {
        get {
            lock.withLock {
                return _logger
            }
        }
        set {
            lock.withLock {
                _logger = newValue
            }
        }
    }

    nonisolated public static func notice(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.notice(tag: tag, message)
    }
    
    nonisolated public static func debug(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.debug(tag: tag, message)
    }
    
    nonisolated public static func trace(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.trace(tag: tag, message)
    }
    
    nonisolated public static func info(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.info(tag: tag, message)
    }
    
    nonisolated public static func error(
        tag: Tag,
        error: (any Error)? = nil,
        _ message: @autoclosure @escaping () -> String
    ) {
        let logger = lock.withLock { return _logger }
        logger.error(tag: tag, error: error, message)
    }
    
    nonisolated public static func warning(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.warning(tag: tag, message)
    }
    
    nonisolated public static func fault(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.fault(tag: tag, message)
    }
    
    nonisolated public static func critical(tag: Tag, _ message: @autoclosure @escaping () -> String) {
        let logger = lock.withLock { return _logger }
        logger.critical(tag: tag, message)
    }
}

extension RiveLog {
    /// Set of enabled severity levels for the built-in logger.
    ///
    /// Use `.default` for practical runtime diagnostics without trace-level noise,
    /// or `.all` to enable every level.
    public struct Level: OptionSet, Sendable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let notice = Level(rawValue: 1 << 0)
        public static let debug = Level(rawValue: 1 << 1)
        public static let trace = Level(rawValue: 1 << 2)
        public static let info = Level(rawValue: 1 << 3)
        public static let error = Level(rawValue: 1 << 4)
        public static let warning = Level(rawValue: 1 << 5)
        public static let fault = Level(rawValue: 1 << 6)
        public static let critical = Level(rawValue: 1 << 7)

        public static let `default`: Level = [
            .debug,
            .warning,
            .error,
            .fault,
            .critical
        ]

        public static let all: Level = [
            .notice,
            .debug,
            .trace,
            .info,
            .error,
            .warning,
            .fault,
            .critical
        ]
    }
}

extension RiveLog {
    /// Structured log categories used by the runtime.
    ///
    /// These values map directly to platform logging categories.
    /// Use `.custom(String)` for stable, non-standard categories.
    public enum Tag: Sendable, Hashable {
        case rive
        case worker
        case file
        case artboard
        case stateMachine
        case viewModelInstance
        case image
        case font
        case audio
        case view
        case custom(String)

        var category: String {
            switch self {
            case .rive: return "Rive"
            case .worker: return "Worker"
            case .file: return "File"
            case .artboard: return "Artboard"
            case .stateMachine: return "StateMachine"
            case .viewModelInstance: return "ViewModelInstance"
            case .image: return "Image"
            case .font: return "Font"
            case .audio: return "Audio"
            case .view: return "RiveUIView"
            case .custom(let value): return value
            }
        }
    }
}

extension RiveLog {
    /// Pluggable logging backend consumed by `RiveLog`.
    ///
    /// Implementations receive lazy message closures and explicit tags so they can
    /// route and format output without incurring message construction cost when
    /// logs are filtered out.
    nonisolated public protocol Logger: Sendable {
        /// Writes a notice message for the given tag.
        nonisolated func notice(tag: Tag, _ message: @escaping () -> String)
        /// Writes a debug message for the given tag.
        nonisolated func debug(tag: Tag, _ message: @escaping () -> String)
        /// Writes a trace message for the given tag.
        nonisolated func trace(tag: Tag, _ message: @escaping () -> String)
        /// Writes an info message for the given tag.
        nonisolated func info(tag: Tag, _ message: @escaping () -> String)
        /// Writes an error message for the given tag.
        ///
        /// - Parameters:
        ///   - tag: Category used for log routing and filtering.
        ///   - error: Optional error context. `nil` if no error object is available.
        ///   - message: Lazily evaluated log message.
        nonisolated func error(tag: Tag, error _: (any Error)?, _ message: @escaping () -> String)
        /// Writes a warning message for the given tag.
        nonisolated func warning(tag: Tag, _ message: @escaping () -> String)
        /// Writes a fault message for the given tag.
        nonisolated func fault(tag: Tag, _ message: @escaping () -> String)
        /// Writes a critical message for the given tag.
        nonisolated func critical(tag: Tag, _ message: @escaping () -> String)
    }
}

extension RiveLog {
    final class NoOpLogger: Logger {
        func notice(tag: Tag, _ message: @escaping () -> String) { }

        func debug(tag: Tag, _ message: @escaping () -> String) { }

        func trace(tag: Tag, _ message: @escaping () -> String) { }

        func info(tag: Tag, _ message: @escaping () -> String) { }

        func error(tag: Tag, error _: (any Error)?, _ message: @escaping () -> String) { }

        func warning(tag: Tag, _ message: @escaping () -> String) { }

        func fault(tag: Tag, _ message: @escaping () -> String) { }

        func critical(tag: Tag, _ message: @escaping () -> String) { }
    }

    final class SystemLogger: Logger, @unchecked Sendable {
        private let subsystem = "app.rive.RiveRuntime"
        private let lock = NSLock()
        private var loggers: [Tag: os.Logger] = [:]
        private let levels: Level

        init(levels: Level = .all) {
            self.levels = levels
        }

        private func logger(for tag: Tag) -> os.Logger {
            lock.withLock {
                if let logger = loggers[tag] {
                    return logger
                }
                let logger = os.Logger(subsystem: subsystem, category: tag.category)
                loggers[tag] = logger
                return logger
            }
        }

        func notice(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.notice) else { return }
            logger(for: tag).notice("\(message())")
        }

        func debug(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.debug) else { return }
            logger(for: tag).debug("\(message())")
        }

        func trace(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.trace) else { return }
            logger(for: tag).trace("\(message())")
        }

        func info(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.info) else { return }
            logger(for: tag).info("\(message())")
        }

        func error(tag: Tag, error: (any Error)?, _ message: @escaping () -> String) {
            guard levels.contains(.error) else { return }
            if let error {
                logger(for: tag).error("\(message()) (Error: \(error.localizedDescription))")
                return
            }
            logger(for: tag).error("\(message())")
        }

        func warning(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.warning) else { return }
            logger(for: tag).warning("\(message())")
        }

        func fault(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.fault) else { return }
            logger(for: tag).fault("\(message())")
        }

        func critical(tag: Tag, _ message: @escaping () -> String) {
            guard levels.contains(.critical) else { return }
            logger(for: tag).critical("\(message())")
        }

    }
}
