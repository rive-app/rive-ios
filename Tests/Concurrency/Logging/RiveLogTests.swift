//
//  RiveLogTests.swift
//  RiveRuntimeTests
//
//  Created by Cursor Assistant on 3/12/26.
//

import Foundation
import XCTest
@testable import RiveRuntime

final class RiveLogTests: XCTestCase {
    override func tearDown() {
        RiveLog.logger = RiveLog.none
        super.tearDown()
    }

    func test_noneLogger_doesNotEvaluateMessage() {
        RiveLog.logger = RiveLog.none

        var didEvaluate = false
        func message() -> String {
            didEvaluate = true
            return "should not evaluate"
        }

        RiveLog.debug(tag: .rive, message())

        XCTAssertFalse(didEvaluate)
    }

    func test_noneLogger_doesNotEvaluateErrorMessage() {
        RiveLog.logger = RiveLog.none

        var didEvaluate = false
        func message() -> String {
            didEvaluate = true
            return "should not evaluate"
        }

        RiveLog.error(tag: .rive, error: TestError.example, message())

        XCTAssertFalse(didEvaluate)
    }

    func test_allNonErrorLevels_forwardTagAndMessageToLogger() {
        let logger = MockLogger()
        RiveLog.logger = logger

        RiveLog.notice(tag: .rive, "[Rive] Notice message")
        RiveLog.debug(tag: .file, "[File] Debug message")
        RiveLog.trace(tag: .stateMachine, "[StateMachine] Trace message")
        RiveLog.info(tag: .custom("MyCustomTag"), "[Custom] Info message")
        RiveLog.warning(tag: .worker, "[Worker] Warning message")
        RiveLog.fault(tag: .artboard, "[Artboard] Fault message")
        RiveLog.critical(tag: .view, "[RiveUIView] Critical message")

        let entries = logger.entries
        XCTAssertEqual(entries.count, 7)

        XCTAssertEqual(entries[0].level, .notice)
        XCTAssertEqual(entries[0].tag, .rive)
        XCTAssertEqual(entries[0].message, "[Rive] Notice message")
        XCTAssertNil(entries[0].errorDescription)

        XCTAssertEqual(entries[1].level, .debug)
        XCTAssertEqual(entries[1].tag, .file)
        XCTAssertEqual(entries[1].message, "[File] Debug message")
        XCTAssertNil(entries[1].errorDescription)

        XCTAssertEqual(entries[2].level, .trace)
        XCTAssertEqual(entries[2].tag, .stateMachine)
        XCTAssertEqual(entries[2].message, "[StateMachine] Trace message")
        XCTAssertNil(entries[2].errorDescription)

        XCTAssertEqual(entries[3].level, .info)
        XCTAssertEqual(entries[3].tag, .custom("MyCustomTag"))
        XCTAssertEqual(entries[3].message, "[Custom] Info message")
        XCTAssertNil(entries[3].errorDescription)

        XCTAssertEqual(entries[4].level, .warning)
        XCTAssertEqual(entries[4].tag, .worker)
        XCTAssertEqual(entries[4].message, "[Worker] Warning message")
        XCTAssertNil(entries[4].errorDescription)

        XCTAssertEqual(entries[5].level, .fault)
        XCTAssertEqual(entries[5].tag, .artboard)
        XCTAssertEqual(entries[5].message, "[Artboard] Fault message")
        XCTAssertNil(entries[5].errorDescription)

        XCTAssertEqual(entries[6].level, .critical)
        XCTAssertEqual(entries[6].tag, .view)
        XCTAssertEqual(entries[6].message, "[RiveUIView] Critical message")
        XCTAssertNil(entries[6].errorDescription)
    }

    func test_error_forwardsTagMessage_andOptionalError() {
        let logger = MockLogger()
        RiveLog.logger = logger

        RiveLog.error(tag: .view, "[RiveUIView] Failed to load")
        RiveLog.error(tag: .view, error: TestError.example, "[RiveUIView] Failed to load")

        let entries = logger.entries
        XCTAssertEqual(entries.count, 2)

        XCTAssertEqual(entries[0].level, .error)
        XCTAssertEqual(entries[0].tag, .view)
        XCTAssertEqual(entries[0].message, "[RiveUIView] Failed to load")
        XCTAssertNil(entries[0].errorDescription)

        XCTAssertEqual(entries[1].level, .error)
        XCTAssertEqual(entries[1].tag, .view)
        XCTAssertEqual(entries[1].message, "[RiveUIView] Failed to load")
        XCTAssertEqual(entries[1].errorDescription, TestError.example.localizedDescription)
    }

    func test_defaultLevel_containsExpectedLevels() {
        let levels = RiveLog.Level.default

        XCTAssertTrue(levels.contains(.debug))
        XCTAssertTrue(levels.contains(.warning))
        XCTAssertTrue(levels.contains(.error))
        XCTAssertTrue(levels.contains(.fault))
        XCTAssertTrue(levels.contains(.critical))

        XCTAssertFalse(levels.contains(.trace))
        XCTAssertFalse(levels.contains(.notice))
        XCTAssertFalse(levels.contains(.info))
    }
}

private enum TestError: LocalizedError {
    case example

    var errorDescription: String? {
        switch self {
        case .example:
            return "Example error"
        }
    }
}

private final class MockLogger: RiveLog.Logger, @unchecked Sendable {
    struct Entry: Equatable {
        let level: Level
        let tag: RiveLog.Tag
        let message: String
        let errorDescription: String?
    }

    enum Level: Equatable {
        case notice
        case debug
        case trace
        case info
        case error
        case warning
        case fault
        case critical
    }

    private let lock = NSLock()
    private var _entries: [Entry] = []

    var entries: [Entry] {
        lock.withLock { _entries }
    }

    func notice(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.notice, tag: tag, message: message(), errorDescription: nil)
    }

    func debug(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.debug, tag: tag, message: message(), errorDescription: nil)
    }

    func trace(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.trace, tag: tag, message: message(), errorDescription: nil)
    }

    func info(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.info, tag: tag, message: message(), errorDescription: nil)
    }

    func error(tag: RiveLog.Tag, error: (any Error)?, _ message: @escaping () -> String) {
        append(.error, tag: tag, message: message(), errorDescription: error?.localizedDescription)
    }

    func warning(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.warning, tag: tag, message: message(), errorDescription: nil)
    }

    func fault(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.fault, tag: tag, message: message(), errorDescription: nil)
    }

    func critical(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        append(.critical, tag: tag, message: message(), errorDescription: nil)
    }

    private func append(_ level: Level, tag: RiveLog.Tag, message: String, errorDescription: String?) {
        lock.withLock {
            _entries.append(
                Entry(
                    level: level,
                    tag: tag,
                    message: message,
                    errorDescription: errorDescription
                )
            )
        }
    }
}
