//
//  RiveLogger.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/20/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

// MARK: - RiveLogLevel

/// An option set of possible log levels, checked when attempting to log.
@objc public class RiveLogLevel: NSObject, OptionSet {
    public var rawValue: Int

    public required init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// A log level that captures debug information
    @objc public static let debug = RiveLogLevel(rawValue: 1 << 0)
    /// A log level that captures additional information.
    @objc public static let info = RiveLogLevel(rawValue: 1 << 1)
    /// The default log level.
    @objc public static let `default` = RiveLogLevel(rawValue: 1 << 2)
    /// A log level that captures an error.
    @objc public static let error = RiveLogLevel(rawValue: 1 << 3)
    /// A log level that captures a fatal error, or fault.
    @objc public static let fault = RiveLogLevel(rawValue: 1 << 4)
    
    /// An option set containing no levels.
    @objc public static let none: RiveLogLevel = []
    /// An option set containing all possible levels.
    @objc public static let all: RiveLogLevel = [.debug, .info, .default, .error, .fault]

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RiveLogLevel else { return false }
        return rawValue == other.rawValue
    }

    public override var hash: Int {
        return rawValue
    }
}

// MARK: - RiveLogCategory

@objc public class RiveLogCategory: NSObject, OptionSet {
    public var rawValue: Int

    public required init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// The category used when logging from a Rive state machine.
    @objc public static let stateMachine = RiveLogCategory(rawValue: 1 << 0)
    /// The category used when logging from a Rive artboard.
    @objc public static let artboard = RiveLogCategory(rawValue: 1 << 1)
    /// The category used when logging from a Rive view model.
    @objc public static let viewModel = RiveLogCategory(rawValue: 1 << 2)
    /// The category used when logging from a Rive model.
    @objc public static let model = RiveLogCategory(rawValue: 1 << 3)
    /// The category used when logging from a Rive file.
    @objc public static let file = RiveLogCategory(rawValue: 1 << 4)
    /// The category used when logging from a Rive view.
    @objc public static let view = RiveLogCategory(rawValue: 1 << 5)
    /// The category used when logging Data Binding.
    @objc public static let dataBinding = RiveLogCategory(rawValue: 1 << 6)

    /// An option set of no categories.
    @objc public static let none: RiveLogCategory = []
    /// An option set containing all possible categories
    @objc public static let all: RiveLogCategory = [.stateMachine, .artboard, .viewModel, .model, .file, .view, .dataBinding]

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RiveLogCategory else { return false }
        return rawValue == other.rawValue
    }

    public override var hash: Int {
        return rawValue
    }
}

// MARK: - RiveLogger

@objc public final class RiveLogger: NSObject {
    static let subsystem = Bundle(for: RiveLogger.self).bundleIdentifier!
    
    /// A Bool indicating whether logging is enabled or not.
    @objc public static var isEnabled = false
    /// A Bool indicating whether verbose logs are enabled or not.
    /// - Note: Logs that emit a constant stream of information, such as state machine advances, are considererd verbose.
    @objc public static var isVerbose = false
    /// A set of levels that should be logged. Only used when `isEnabled` is set to `true`.
    @objc public static var levels: RiveLogLevel = .all
    /// A set of categories that should be logged. Only used when `isEnabled` is set to `true`.
    @objc public static var categories: RiveLogCategory = .all
}
