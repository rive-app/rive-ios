//
//  CustomLogger.swift
//  RiveRuntime
//
//  Created by Tyler Nijmeh (Work) on 4/8/26.
//

import Foundation
import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

struct CustomLoggerView: View {
    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(source: .local("logpanel", Bundle.main), worker: worker)
            let rive = try await Rive(file: file)
            RiveLog.logger = SimpleRiveLogger(
                viewModelInstance: rive.viewModelInstance
            )
            return rive
        }
    }
}

struct StringLineBuffer {
    private let maxLines: Int
    private var lines: [String] = []

    init(maxLines: Int = 50) {
        self.maxLines = max(1, maxLines)
        self.lines.reserveCapacity(maxLines)
    }

    mutating func append(_ line: String) {
        lines.append(line)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines) // drop oldest
        }
    }

    var allLines: [String] { lines }
    var joined: String { lines.joined(separator: "\n") }
}

private final class SimpleRiveLogger: RiveLog.Logger, @unchecked Sendable {
    private let sink: VmiLogSink
    private let lock = NSLock()
    private let flushQueue = DispatchQueue(label: "SimpleRiveLogger.flush")
    private var pendingLines: [String] = []
    private var isFlushScheduled = false
    private var previousLineHash: Int?
    private var previousLine: String?
    private let flushInterval: DispatchTimeInterval = .milliseconds(500)
    private let maxPendingLines = 20

    init(viewModelInstance: ViewModelInstance?) {
        sink = VmiLogSink(viewModelInstance: viewModelInstance)
    }

    nonisolated private func log(
        level: String,
        tag: RiveLog.Tag,
        error: (any Error)? = nil,
        _ message: @escaping () -> String
    ) {
        let line: String
        if let error {
            line = "[\(level)][\(String(describing: tag))] \(message()) | error: \(error.localizedDescription)"
        } else {
            line = "[\(level)][\(String(describing: tag))] \(message())"
        }

        lock.lock()
        let lineHash = line.hashValue
        if previousLineHash == lineHash && previousLine == line {
            lock.unlock()
            return
        }

        previousLineHash = lineHash
        previousLine = line
        pendingLines.append(line)
        if pendingLines.count > maxPendingLines {
            pendingLines.removeFirst(pendingLines.count - maxPendingLines)
        }

        if isFlushScheduled {
            lock.unlock()
            return
        }
        isFlushScheduled = true
        lock.unlock()

        flushQueue.asyncAfter(deadline: .now() + flushInterval) { [weak self] in
            self?.flushPending()
        }
    }

    private func flushPending() {
        lock.lock()
        let lines = pendingLines
        pendingLines.removeAll(keepingCapacity: true)
        isFlushScheduled = false
        lock.unlock()

        guard !lines.isEmpty else {
            return
        }

        Task {
            await sink.append(contentsOf: lines)
        }
    }

    nonisolated func notice(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "notice", tag: tag, message)
    }

    nonisolated func debug(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "debug", tag: tag, message)
    }

    nonisolated func trace(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "trace", tag: tag, message)
    }

    nonisolated func info(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "info", tag: tag, message)
    }

    nonisolated func error(tag: RiveLog.Tag, error: (any Error)?, _ message: @escaping () -> String) {
        log(level: "error", tag: tag, error: error, message)
    }

    nonisolated func warning(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "warning", tag: tag, message)
    }

    nonisolated func fault(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "fault", tag: tag, message)
    }

    nonisolated func critical(tag: RiveLog.Tag, _ message: @escaping () -> String) {
        log(level: "critical", tag: tag, message)
    }
}

private actor VmiLogSink {
    private weak var viewModelInstance: ViewModelInstance?
    private var stringLineBuffer = StringLineBuffer(maxLines: 50)
    private let logProperty = StringProperty(path: "logger/content")

    init(viewModelInstance: ViewModelInstance?) {
        self.viewModelInstance = viewModelInstance
    }

    func append(contentsOf lines: [String]) async {
        for line in lines {
            stringLineBuffer.append(line)
        }
        let joined = stringLineBuffer.joined
        let viewModelInstance = self.viewModelInstance
        await MainActor.run {
            viewModelInstance?.setValue(of: logProperty, to: joined)
        }
    }
}
