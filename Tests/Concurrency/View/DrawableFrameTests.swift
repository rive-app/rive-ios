import Metal
import QuartzCore
import XCTest
@testable import RiveRuntime

final class DrawableFrameTests: XCTestCase {
    @MainActor
    func test_beginFrame_usesFullDrawableCapacity() {
        for poolSize in [2, 3] {
            let layer = CAMetalLayer()
            layer.maximumDrawableCount = poolSize
            let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
            var pending: [RiveUIView.DrawableFrame] = []
            for _ in 0..<poolSize {
                guard let frame = coordinator.beginFrame({ FrameTestDrawable {} }) else {
                    XCTFail("Expected capacity for \(poolSize) queued frames")
                    return
                }
                pending.append(frame)
            }

            // Every pool slot is occupied until release and presentation finish.
            withExtendedLifetime(pending) {
                assertUnavailable(coordinator)
            }

            // Discarded frames return capacity through the same retirement path.
            pending.removeAll()
            let replacement = coordinator.beginFrame { FrameTestDrawable {} }
            XCTAssertNotNil(replacement)
        }
    }

    @MainActor
    func test_beginFrame_exhaustedBudgetDoesNotRequestAnotherDrawable() {
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        let frame = coordinator.beginFrame { FrameTestDrawable {} }
        XCTAssertNotNil(frame)
        withExtendedLifetime(frame) {
            assertUnavailable(coordinator)
        }
    }

    @MainActor
    func test_beginFrame_failedProviderReturnsPermit() {
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        XCTAssertNil(coordinator.beginFrame { nil })
        assertOneAvailable(coordinator)
    }

    @MainActor
    func test_beginFrame_drainsDiscardedDrawableBeforeRequestingAnother() {
        let retired = expectation(description: "Drawable retired")
        retired.assertForOverFulfill = true
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        let pending = makeCallback(coordinator: coordinator) {
            XCTAssertTrue(Thread.isMainThread)
            retired.fulfill()
        }
        let discarded = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            pending.callback = nil
            discarded.signal()
        }

        // Keep main occupied so the fallback cannot perform cleanup first.
        XCTAssertEqual(discarded.wait(timeout: .now() + 1), .success)
        let replacement = coordinator.beginFrame {
            wait(for: [retired], timeout: 0)
            return FrameTestDrawable {}
        }
        XCTAssertNotNil(replacement)
        withExtendedLifetime(replacement) {
            coordinator.drain()
            coordinator.drain()
            assertUnavailable(coordinator)
        }
    }

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
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        let pending = makeCallback(coordinator: coordinator) {
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
        assertOneAvailable(coordinator)
    }

    @MainActor
    func test_presentedCallback_waitsForGPUCompletion() async {
        await assertPresentedPermit(completesBeforeCallbackRelease: false)
    }

    @MainActor
    func test_presentedCallback_GPUCompletionWaitsForRenderingCallbackRelease() async {
        await assertPresentedPermit(completesBeforeCallbackRelease: true)
    }

    @MainActor
    func test_present_leavesCommitToRenderer_andRetainsFrameUntilCompletion() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let commandBuffer = try XCTUnwrap(queue.makeCommandBuffer())
        let layer = CAMetalLayer()
        layer.device = device
        layer.drawableSize = CGSize(width: 1, height: 1)
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        var frame: RiveUIView.DrawableFrame? = try XCTUnwrap(coordinator.beginFrame { layer.nextDrawable() })
        weak var retainedFrame = frame
        frame!.present(on: commandBuffer)
        frame = nil

        XCTAssertEqual(commandBuffer.status, .notEnqueued, "The renderer owns commit")
        XCTAssertNotNil(retainedFrame, "GPU completion must retain the drawable frame")
        assertUnavailable(coordinator)

        let completed = expectation(description: "Command buffer completed")
        commandBuffer.addCompletedHandler { buffer in
            XCTAssertEqual(buffer.status, .completed)
            completed.fulfill()
        }
        commandBuffer.commit()
        wait(for: [completed], timeout: 5)
    }

    @MainActor
    func test_presentationAndRetirement_bothRequiredToReturnCapacity() {
        for presentationFirst in [false, true] {
            let layer = CAMetalLayer()
            layer.maximumDrawableCount = 2
            let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
            // Occupy one slot so this test exercises the last available permit.
            let occupied = coordinator.beginFrame { FrameTestDrawable {} }
            defer { withExtendedLifetime(occupied) {} }
            let released = expectation(description: "Drawable released before presentation handler is discarded")
            var frame = coordinator.beginFrame {
                FrameTestDrawable {
                    XCTAssertTrue(Thread.isMainThread)
                    released.fulfill()
                }
            }
            // Keep the handler alive independently, as Core Animation does.
            let presented = frame!.presentationHandler()
            let callbackArgument = FrameTestDrawable {}
            if presentationFirst {
                presented(callbackArgument)
                assertUnavailable(coordinator)
            }

            // Dropping the final owner models rendering/GPU callbacks finishing.
            frame = nil
            coordinator.drain()
            wait(for: [released], timeout: 0)
            if !presentationFirst {
                assertUnavailable(coordinator)
                presented(callbackArgument)
            }
            assertOneAvailable(coordinator)
        }
    }

    @MainActor
    func test_presentationFailure_returnsCapacityWithoutPresentationOnlyOnce() {
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        var frame = coordinator.beginFrame { FrameTestDrawable {} }
        let presented = frame!.presentationHandler()
        frame!.didFailToPresent()
        assertUnavailable(coordinator)
        frame = nil
        assertOneAvailable(coordinator)

        // A late callback after an error must not return a second permit.
        presented(FrameTestDrawable {})
        assertOneAvailable(coordinator)
    }

    @MainActor
    private func assertPresentedPermit(completesBeforeCallbackRelease: Bool) async {
        let released = expectation(description: "Presented drawable retired")
        let firstCallbackReleased = expectation(description: "First callback released")
        let secondCallbackReleased = expectation(description: "Second callback released")
        let layer = CAMetalLayer()
        layer.maximumDrawableCount = 2
        let coordinator = RiveUIView.DrawableCoordinator(layer: layer)
        // Occupy one slot so this test exercises the last available permit.
        let occupied = coordinator.beginFrame { FrameTestDrawable {} }
        defer { withExtendedLifetime(occupied) {} }
        let (pending, completion) = makePresentedCallback(coordinator: coordinator) {
            XCTAssertTrue(Thread.isMainThread)
            released.fulfill()
        }

        DispatchQueue.global().async {
            pending.callback?()
            if completesBeforeCallbackRelease {
                completion.callback?()
                completion.callback = nil
            } else {
                pending.callback = nil
            }
            firstCallbackReleased.fulfill()
        }
        await fulfillment(of: [firstCallbackReleased], timeout: 5)
        assertUnavailable(coordinator)

        DispatchQueue.global().async {
            if completesBeforeCallbackRelease {
                pending.callback = nil
            } else {
                completion.callback?()
                completion.callback = nil
            }
            secondCallbackReleased.fulfill()
        }
        await fulfillment(of: [secondCallbackReleased, released], timeout: 5)
        assertOneAvailable(coordinator)
    }

    @MainActor
    private func assertUnavailable(
        _ coordinator: RiveUIView.DrawableCoordinator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(coordinator.beginFrame {
            XCTFail("No drawable should be requested without a permit", file: file, line: line)
            return nil
        }, file: file, line: line)
    }

    @MainActor
    private func assertOneAvailable(_ coordinator: RiveUIView.DrawableCoordinator) {
        let frame = coordinator.beginFrame { FrameTestDrawable {} }
        XCTAssertNotNil(frame)
        withExtendedLifetime(frame) {
            assertUnavailable(coordinator)
        }
    }

    @MainActor
    private func makePresentedCallback(
        coordinator: RiveUIView.DrawableCoordinator,
        onRelease: @escaping @Sendable () -> Void
    ) -> (PendingCallback, PendingCallback) {
        let frame = coordinator.beginFrame { FrameTestDrawable(onRelease: onRelease) }!
        let pending = PendingCallback {
            XCTAssertNotNil(frame.drawable)
        }
        let completion = PendingCallback { withExtendedLifetime(frame) {} }
        return (pending, completion)
    }

    @MainActor
    private func makeCallback(
        coordinator: RiveUIView.DrawableCoordinator,
        onRelease: @escaping @Sendable () -> Void
    ) -> PendingCallback {
        let frame = coordinator.beginFrame { FrameTestDrawable(onRelease: onRelease) }!
        return PendingCallback {
            XCTAssertNotNil(frame.drawable, "Drawable must survive callback execution")
        }
    }
}

private final class PendingCallback: @unchecked Sendable {
    var callback: (@Sendable () -> Void)?

    init(_ callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }
}

private final class FrameTestDrawable: NSObject, CAMetalDrawable {
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
