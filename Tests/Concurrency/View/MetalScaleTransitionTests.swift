import UIKit
import MetalKit
import XCTest
@testable import RiveRuntime

final class MetalScaleTransitionTests: XCTestCase {
    @MainActor
    func test_rotation() async throws {
        try await assertTransformSizing(CGAffineTransform(rotationAngle: 14 * .pi / 180))
    }

    @MainActor
    func test_quarterTurn() async throws {
        try await assertTransformSizing(CGAffineTransform(rotationAngle: .pi / 2))
    }

    @MainActor
    func test_zeroScale() async throws {
        try await assertTransformSizing(CGAffineTransform(scaleX: 0, y: 0))
    }

    @MainActor
    func test_smallScale() async throws {
        try await assertTransformSizing(CGAffineTransform(scaleX: 0.01, y: 0.01))
    }

    @MainActor
    func test_nonuniformScale() async throws {
        try await assertTransformSizing(CGAffineTransform(scaleX: 0.1, y: 2))
    }

    @MainActor
    func test_horizontalMirror() async throws {
        try await assertTransformSizing(CGAffineTransform(scaleX: -1, y: 1))
    }

    @MainActor
    func test_verticalMirror() async throws {
        try await assertTransformSizing(CGAffineTransform(scaleX: 1, y: -1))
    }

    @MainActor
    func test_translation() async throws {
        try await assertTransformSizing(CGAffineTransform(translationX: 13.25, y: -7.5))
    }

    @MainActor
    func test_shear() async throws {
        try await assertTransformSizing(CGAffineTransform(a: 1, b: 0.2, c: 0.3, d: 1, tx: 0, ty: 0))
    }

    @MainActor
    func test_combinedRotationAndScale() async throws {
        try await assertTransformSizing(
            CGAffineTransform(rotationAngle: 14 * .pi / 180).scaledBy(x: -0.1, y: 2)
        )
    }

    @MainActor
    func test_nestedRotationAndScale() async throws {
        try await assertDrawableSizing(ancestors: [
            CGAffineTransform(scaleX: -0.1, y: 2),
            CGAffineTransform(rotationAngle: 14 * .pi / 180)
        ])
    }

    @MainActor
    func test_nestedCancellingRotations() async throws {
        try await assertDrawableSizing(ancestors: [
            CGAffineTransform(rotationAngle: 14 * .pi / 180),
            CGAffineTransform(rotationAngle: -14 * .pi / 180)
        ])
    }

    @MainActor
    private func assertTransformSizing(_ transform: CGAffineTransform) async throws {
        try await assertDrawableSizing(ancestors: [transform])
        // An unchanged immediate parent must not hide a transformed grandparent.
        try await assertDrawableSizing(ancestors: [.identity, transform])
    }

    @MainActor
    private func assertDrawableSizing(ancestors: [CGAffineTransform]) async throws {
        for legacy in [false, true] {
            try await checkScaleTransition(legacy: legacy, ancestors: ancestors)
        }
    }

    @MainActor
    private func checkScaleTransition(legacy: Bool, ancestors: [CGAffineTransform]) async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        defer { window.isHidden = true }
        let size = CGSize(width: 100, height: 148)
        let control: UIView = legacy ? RiveView() : RiveUIView(rive: nil)
        let subject: UIView = legacy ? RiveView() : RiveUIView(rive: nil)
        control.frame = CGRect(origin: .zero, size: size)
        subject.frame = CGRect(origin: .zero, size: size)
        func metal(in view: UIView) -> MTKView? {
            (view as? MTKView) ?? view.subviews.lazy.compactMap { metal(in: $0) }.first
        }
        for _ in 0..<100 {
            if metal(in: control) != nil && metal(in: subject) != nil { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        let controlMetal = try XCTUnwrap(metal(in: control))
        let subjectMetal = try XCTUnwrap(metal(in: subject))
        let nativeScale = window.screen.nativeScale
        for view in [control, subject] {
            view.layoutIfNeeded()
            let metalView = try XCTUnwrap(metal(in: view))
            // Force a scale transition even when display and native scales match.
            metalView.contentScaleFactor = nativeScale / 2
            metalView.setNeedsLayout()
            metalView.layoutIfNeeded()
        }

        var root = subject
        var parents = [UIView]()
        for transform in ancestors {
            let parent = UIView(frame: CGRect(origin: .zero, size: size))
            parent.addSubview(root)
            parent.transform = transform
            parents.append(parent)
            root = parent
        }
        window.addSubview(control)
        window.addSubview(root)
        window.isHidden = false
        window.layoutIfNeeded()

        let context = "\(legacy ? "RiveView" : "RiveUIView"), ancestors: \(ancestors)"
        func assertDrawable(_ phase: String) {
            let message = "\(context), \(phase)"
            XCTAssertTrue(subjectMetal === metal(in: subject), message)
            XCTAssertEqual(subjectMetal.bounds.size, controlMetal.bounds.size, message)
            for metalView in [controlMetal, subjectMetal] {
                XCTAssertTrue(metalView.autoResizeDrawable, message)
                XCTAssertTrue(metalView.drawableSize.width.isFinite && metalView.drawableSize.height.isFinite, message)
                XCTAssertEqual(metalView.drawableSize.width, metalView.bounds.width * nativeScale, accuracy: 1, message)
                XCTAssertEqual(metalView.drawableSize.height, metalView.bounds.height * nativeScale, accuracy: 1, message)
            }
            XCTAssertEqual(subjectMetal.drawableSize, controlMetal.drawableSize, message)
        }
        assertDrawable("attached with transforms")

        // Resize without changing the transforms, including singular transforms.
        for view in [control, subject] {
            view.bounds.size = CGSize(width: 123, height: 181)
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
        assertDrawable("resized with transforms")

        parents.forEach { $0.transform = .identity }
        window.layoutIfNeeded()
        assertDrawable("restored to identity")

        root.removeFromSuperview()
        for (parent, transform) in zip(parents, ancestors) { parent.transform = transform }
        window.addSubview(root)
        window.layoutIfNeeded()
        assertDrawable("reattached with transforms")
    }
}
