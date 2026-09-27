//
//  AncestorTransformView.swift
//  RiveExample
//
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import MetalKit
import RiveRuntime

/// Rive views whose ancestor is rotated or scaled to zero when first attached to a window.
///
/// Only reproduces where `UIScreen.nativeScale != UIScreen.scale` (e.g. iPhone mini / Plus,
/// or any iPhone with Display Zoom). Every artboard should keep the same aspect ratio, and the
/// status line should read `ok` for each view.
struct AncestorTransformView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AncestorTransformViewController {
        AncestorTransformViewController()
    }

    func updateUIViewController(_ uiViewController: AncestorTransformViewController, context: Context) {}
}

final class AncestorTransformViewController: UIViewController {
    private let cellSize = CGSize(width: 100, height: 148)
    private var heightConstraints: [NSLayoutConstraint] = []
    private let statusLabel = UILabel()
    private var statusTimer: Timer?
    private var legacyViewModels: [RiveViewModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.numberOfLines = 0
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.accessibilityIdentifier = "ancestorTransformStatus"

        let resize = UIButton(type: .system)
        resize.setTitle("Toggle height", for: .normal)
        resize.addTarget(self, action: #selector(toggleHeight), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            makeRow(title: "RiveUIView", makeView: makeRiveUIView),
            makeRow(title: "RiveView (legacy)", makeView: makeLegacyRiveView),
            resize,
            statusLabel,
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        statusTimer?.invalidate()
    }

    private func makeRow(title: String, makeView: () -> UIView) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline)

        let identity = UIView()
        let rotated = UIView()
        rotated.transform = CGAffineTransform(rotationAngle: 14 * .pi / 180)
        let zeroScaled = UIView()
        zeroScaled.transform = CGAffineTransform(scaleX: 0, y: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3) { zeroScaled.transform = .identity }
        }

        let cells = [identity, rotated, zeroScaled].map { container -> UIView in
            container.layer.borderColor = UIColor.systemGray3.cgColor
            container.layer.borderWidth = 1
            container.translatesAutoresizingMaskIntoConstraints = false
            let height = container.heightAnchor.constraint(equalToConstant: cellSize.height)
            heightConstraints.append(height)
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: cellSize.width),
                height,
            ])
            let rive = makeView()
            rive.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(rive)
            NSLayoutConstraint.activate([
                rive.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                rive.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                rive.topAnchor.constraint(equalTo: container.topAnchor),
                rive.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            return container
        }

        let row = UIStackView(arrangedSubviews: cells)
        row.spacing = 12
        let column = UIStackView(arrangedSubviews: [label, row])
        column.axis = .vertical
        column.spacing = 8
        return column
    }

    private func makeRiveUIView() -> UIView {
        RiveUIView(rive: {
            let worker = try await Worker()
            let file = try await File(source: .local("rewards", Bundle.main), worker: worker)
            return try await Rive(file: file)
        })
    }

    private func makeLegacyRiveView() -> UIView {
        let viewModel = RiveViewModel(fileName: "rewards", fit: .contain)
        legacyViewModels.append(viewModel)
        return viewModel.createRiveView()
    }

    @objc private func toggleHeight() {
        let tall = heightConstraints.first?.constant == cellSize.height
        heightConstraints.forEach { $0.constant = tall ? cellSize.height * 1.3 : cellSize.height }
    }

    private func updateStatus() {
        guard let nativeScale = view.window?.screen.nativeScale,
              let scale = view.window?.screen.scale else { return }
        var lines = ["scale \(scale)  nativeScale \(nativeScale)"]
        for mtkView in allMTKViews(in: view) {
            let expected = CGSize(
                width: (mtkView.bounds.width * nativeScale).rounded(),
                height: (mtkView.bounds.height * nativeScale).rounded()
            )
            let size = mtkView.drawableSize
            let ok = abs(size.width - expected.width) <= 1 && abs(size.height - expected.height) <= 1
            lines.append(String(
                format: "%@ %4.0f×%-4.0f expected %4.0f×%-4.0f %@",
                mtkView is RiveView ? "legacy" : "new   ",
                size.width, size.height, expected.width, expected.height,
                ok ? "ok" : "BAD"
            ))
        }
        statusLabel.text = lines.joined(separator: "\n")
    }

    private func allMTKViews(in root: UIView) -> [MTKView] {
        if let mtkView = root as? MTKView { return [mtkView] }
        return root.subviews.flatMap(allMTKViews)
    }
}
