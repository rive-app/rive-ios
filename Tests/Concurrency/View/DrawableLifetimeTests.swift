import Metal
import QuartzCore
import XCTest
@testable import RiveRuntime

final class DrawableLifetimeTests: XCTestCase {
    @MainActor
    func test_discardedCallback_releasesDrawableOnMain() async {
        await assertDrawableRetiresOnMain(executeCallback: false)
    }

    @MainActor
    func test_executedCallback_releasesDrawableOnMain() async {
        await assertDrawableRetiresOnMain(executeCallback: true)
    }

    @MainActor
    private func assertDrawableRetiresOnMain(executeCallback: Bool) async {
        let released = expectation(description: "Drawable released on main")
        let discarded = expectation(description: "Callback discarded on worker")
        let semaphore = DispatchSemaphore(value: 0)
        let pending = makeCallback(semaphore: semaphore) {
            XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut, "Permit returned before drawable release")
            XCTAssertTrue(Thread.isMainThread, "Final drawable release must occur on main")
            released.fulfill()
        }

        DispatchQueue.global().async {
            XCTAssertFalse(Thread.isMainThread)
            autoreleasepool {
                if executeCallback {
                    pending.callback?()
                }
                pending.callback = nil
            }
            discarded.fulfill()
        }

        await fulfillment(of: [discarded, released], timeout: 5)
        XCTAssertEqual(semaphore.wait(timeout: .now()), .success)
        XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
    }

    @MainActor
    func test_presentedCallback_retirementDoesNotReturnPermitBeforeCompletion() async {
        await assertPresentedPermit(completesBeforeRetirement: false)
    }

    @MainActor
    func test_presentedCallback_completionBeforeRetirementReturnsPermitOnlyOnce() async {
        await assertPresentedPermit(completesBeforeRetirement: true)
    }

    @MainActor
    private func assertPresentedPermit(completesBeforeRetirement: Bool) async {
        let released = expectation(description: "Presented drawable retired")
        let discarded = expectation(description: "Presented callback discarded")
        let completed = expectation(description: "GPU completion callback")
        let semaphore = DispatchSemaphore(value: 0)
        let (pending, completion) = makePresentedCallback(semaphore: semaphore) {
            XCTAssertTrue(Thread.isMainThread)
            released.fulfill()
        }

        DispatchQueue.global().async {
            pending.callback?()
            if completesBeforeRetirement {
                completion.callback?()
                completion.callback = nil
            }
            pending.callback = nil
            discarded.fulfill()
        }
        await fulfillment(of: [discarded, released], timeout: 5)

        if !completesBeforeRetirement {
            XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
        }
        DispatchQueue.global().async {
            if !completesBeforeRetirement {
                completion.callback?()
                completion.callback = nil
            }
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 5)
        XCTAssertEqual(semaphore.wait(timeout: .now()), .success)
        XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
    }

    @MainActor
    private func makePresentedCallback(
        semaphore: DispatchSemaphore,
        onRelease: @escaping @Sendable () -> Void
    ) -> (PendingCallback, PendingCallback) {
        let token = RiveUIView.DrawableToken(semaphore)
        let lifetime = RiveUIView.DrawableLifetime(
            LifetimeTestDrawable(onRelease: onRelease), token: token
        )
        let pending = PendingCallback {
            XCTAssertNotNil(lifetime.drawable)
            lifetime.markPresented()
        }
        let completion = PendingCallback { token.signal() }
        return (pending, completion)
    }

    @MainActor
    private func makeCallback(semaphore: DispatchSemaphore, onRelease: @escaping @Sendable () -> Void) -> PendingCallback {
        let lifetime = RiveUIView.DrawableLifetime(
            LifetimeTestDrawable(onRelease: onRelease),
            token: RiveUIView.DrawableToken(semaphore)
        )
        return PendingCallback {
            XCTAssertNotNil(lifetime.drawable, "Drawable must survive callback execution")
        }
    }
}

private final class PendingCallback: @unchecked Sendable {
    var callback: (@Sendable () -> Void)?

    init(_ callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }
}

private final class LifetimeTestDrawable: NSObject, CAMetalDrawable {
    private let onRelease: @Sendable () -> Void

    init(onRelease: @escaping @Sendable () -> Void) {
        self.onRelease = onRelease
        super.init()
    }

    var texture: MTLTexture { fatalError("This test does not render") }
    var layer: CAMetalLayer { fatalError("This test does not access a layer") }
    var presentedTime: CFTimeInterval { 0 }
    var drawableID: Int { 0 }
    func addPresentedHandler(_ block: @escaping MTLDrawablePresentedHandler) {}
    func present() {}
    func present(at presentationTime: CFTimeInterval) {}
    func present(afterMinimumDuration duration: CFTimeInterval) {}

    deinit {
        onRelease()
    }
}
