import XCTest
@testable import RiveRuntime

final class DrawableTokenTests: XCTestCase {
    private let drawableCount = 3

    private func makeSemaphore() -> DispatchSemaphore {
        DispatchSemaphore(value: drawableCount)
    }

    private func assertSemaphoreValue(
        _ semaphore: DispatchSemaphore,
        equals expected: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for i in 0..<expected {
            XCTAssertEqual(
                semaphore.wait(timeout: .now()), .success,
                "Expected value >= \(expected) but wait #\(i + 1) timed out",
                file: file, line: line
            )
        }
        XCTAssertEqual(
            semaphore.wait(timeout: .now()), .timedOut,
            "Expected value == \(expected) but an extra wait succeeded",
            file: file, line: line
        )
        for _ in 0..<expected {
            semaphore.signal()
        }
    }

    func test_signal_restoresSemaphoreAfterWait() {
        let semaphore = makeSemaphore()
        semaphore.wait()
        let token = RiveUIView.DrawableToken(semaphore)

        token.signal()

        assertSemaphoreValue(semaphore, equals: drawableCount)
    }

    func test_signal_isIdempotent() {
        let semaphore = makeSemaphore()
        semaphore.wait()
        let token = RiveUIView.DrawableToken(semaphore)

        token.signal()
        token.signal()
        token.signal()

        assertSemaphoreValue(semaphore, equals: drawableCount)
    }

    func test_deinit_signalsWhenNeverExplicitlySignaled() {
        let semaphore = makeSemaphore()
        semaphore.wait()

        do {
            _ = RiveUIView.DrawableToken(semaphore)
        }

        assertSemaphoreValue(semaphore, equals: drawableCount)
    }

    func test_deinit_doesNotDoubleSignalAfterExplicitSignal() {
        let semaphore = makeSemaphore()
        semaphore.wait()

        do {
            let token = RiveUIView.DrawableToken(semaphore)
            token.signal()
        }

        assertSemaphoreValue(semaphore, equals: drawableCount)
    }

    func test_concurrentSignals_signalExactlyOnce() {
        let semaphore = makeSemaphore()
        semaphore.wait()
        let token = RiveUIView.DrawableToken(semaphore)
        let iterations = 100
        let group = DispatchGroup()

        for _ in 0..<iterations {
            group.enter()
            DispatchQueue.global().async {
                token.signal()
                group.leave()
            }
        }

        group.wait()

        assertSemaphoreValue(semaphore, equals: drawableCount)
    }
}
