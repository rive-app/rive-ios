//
//  MainThreadBlockView.swift
//  RiveExample
//
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import UIKit
import RiveRuntime

/// Blocks the main thread in bursts and shows how fast each RiveUIView keeps presenting.
///
/// Launch arguments, for scripted measurement:
/// `-blockDemoMode main|offMain|both|spinner`, `-blockDemoAutorun 62|8|freeze`, `-blockDemoFile <name>`,
/// `-blockDemoChurn YES` (set a view model number every 50 ms from main).
struct MainThreadBlockView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainThreadBlockViewController {
        MainThreadBlockViewController()
    }

    func updateUIViewController(_ uiViewController: MainThreadBlockViewController, context: Context) {}
}

final class MainThreadBlockViewController: UIViewController {
    private enum Mode: String, CaseIterable {
        case main, offMain, both, spinner

        var title: String {
            switch self {
            case .main: return "Main"
            case .offMain: return "Off-main"
            case .both: return "Both"
            case .spinner: return "Spinner"
            }
        }
    }

    private struct Load {
        let busy: TimeInterval
        let free: TimeInterval
        var duration: TimeInterval = 10

        static let freeze = Load(busy: 3, free: 0, duration: 3)

        var title: String {
            free == 0
                ? String(format: "frozen %.0f s", busy)
                : String(format: "blocking %.0f/%.0f ms", busy * 1000, free * 1000)
        }
    }

    private let defaults = UserDefaults.standard
    private lazy var mode = Mode(rawValue: defaults.string(forKey: "blockDemoMode") ?? "") ?? .both
    private lazy var fileName = defaults.string(forKey: "blockDemoFile") ?? "GradientBorder"

    private let modeControl = UISegmentedControl()
    private let stage = UIStackView()
    private let phaseLabel = UILabel()
    private let statsLabel = UILabel()
    private var cells: [(title: String, view: UIView, label: UILabel, lastCount: Int)] = []
    private var statsTimer: Timer?
    private var mainLink: CADisplayLink?
    private var churnTimer: Timer?
    private var lifecycleTimer: Timer?
    private var stageHeight: NSLayoutConstraint?
    private var runID = 0
    private var viewModelInstances: [ViewModelInstance] = []
    private var mainTicks = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        for (index, mode) in Mode.allCases.enumerated() {
            modeControl.insertSegment(withTitle: mode.title, at: index, animated: false)
        }
        modeControl.selectedSegmentIndex = Mode.allCases.firstIndex(of: mode) ?? 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        stage.axis = .horizontal
        stage.distribution = .fillEqually
        stage.spacing = 8

        phaseLabel.font = .monospacedSystemFont(ofSize: 22, weight: .bold)
        phaseLabel.textAlignment = .center
        phaseLabel.text = "idle"

        statsLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        statsLabel.numberOfLines = 0
        statsLabel.textAlignment = .center

        let run62 = button("Block 62 ms / free 50 ms") { [weak self] in self?.run(Load(busy: 0.062, free: 0.050)) }
        let run8 = button("Block 8 ms / free 8 ms") { [weak self] in self?.run(Load(busy: 0.008, free: 0.008)) }
        let freeze = button("Freeze 3 s (single block)") { [weak self] in self?.run(.freeze) }
        let churn = UISwitch()
        churn.isOn = defaults.bool(forKey: "blockDemoChurn")
        churn.addAction(UIAction { [weak self] action in
            self?.setChurn((action.sender as? UISwitch)?.isOn ?? false)
        }, for: .valueChanged)
        let churnRow = UIStackView(arrangedSubviews: [label("Data-binding churn (50 ms)"), churn])
        churnRow.spacing = 8

        let column = UIStackView(arrangedSubviews: [modeControl, stage, phaseLabel, statsLabel, run62, run8, freeze, churnRow])
        column.axis = .vertical
        column.spacing = 12
        column.alignment = .fill
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            column.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
        ])
        stageHeight = stage.heightAnchor.constraint(equalToConstant: 300)
        stageHeight?.isActive = true

        rebuildStage()
        setChurn(churn.isOn)
        if defaults.bool(forKey: "blockDemoLifecycle") {
            startLifecycleStress()
        }

        let mainLink = CADisplayLink(target: self, selector: #selector(mainTick))
        mainLink.add(to: .main, forMode: .common)
        self.mainLink = mainLink

        statsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateStats() }
        }

        switch defaults.string(forKey: "blockDemoAutorun") {
        case "62": run(Load(busy: 0.062, free: 0.050))
        case "8": run(Load(busy: 0.008, free: 0.008))
        case "freeze": run(.freeze)
        default: break
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        statsTimer?.invalidate()
        churnTimer?.invalidate()
        lifecycleTimer?.invalidate()
        mainLink?.invalidate()
        runID += 1
    }

    @objc private func mainTick() {
        mainTicks += 1
    }

    @objc private func modeChanged() {
        mode = Mode.allCases[modeControl.selectedSegmentIndex]
        rebuildStage()
    }

    private func rebuildStage() {
        stage.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cells = []
        viewModelInstances = []
        switch mode {
        case .main:
            addRiveCell(title: "main thread", offMain: false)
        case .offMain:
            addRiveCell(title: "off-main", offMain: true)
        case .both:
            addRiveCell(title: "main thread", offMain: false)
            addRiveCell(title: "off-main", offMain: true)
        case .spinner:
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            spinner.transform = CGAffineTransform(scaleX: 3, y: 3)
            addCell(title: "UIActivityIndicatorView", content: spinner)
        }
    }

    private func addRiveCell(title: String, offMain: Bool) {
        let fileName = fileName
        RiveUIView.Experimental.offMainRendering = offMain
        let riveView = RiveUIView(rive: { [weak self] in
            let worker = try await Worker()
            let file = try await File(source: .local(fileName, .main), worker: worker)
            let artboard = try await file.createArtboard()
            let stateMachine = try await artboard.createStateMachine()
            if let instance = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard))) {
                try await stateMachine.bindViewModelInstances(main: instance)
                self?.viewModelInstances.append(instance)
            }
            return try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)
        })
        RiveUIView.Experimental.offMainRendering = false
        addCell(title: title, content: riveView)
    }

    private func addCell(title: String, content: UIView) {
        let label = label(title)
        label.textAlignment = .center
        label.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        let cell = UIStackView(arrangedSubviews: [content, label])
        cell.axis = .vertical
        cell.layer.borderColor = UIColor.separator.cgColor
        cell.layer.borderWidth = 1
        stage.addArrangedSubview(cell)
        cells.append((title, content, label, (content as? RiveUIView)?._presentedFrameCount ?? 0))
    }

    private func updateStats() {
        for index in cells.indices {
            guard let riveView = cells[index].view as? RiveUIView else { continue }
            let count = riveView._presentedFrameCount
            cells[index].label.text = "\(cells[index].title)\n\(count - cells[index].lastCount) fps"
            cells[index].label.numberOfLines = 2
            cells[index].lastCount = count
        }
        let rates = cells.map { "\($0.title)=\($0.label.text?.split(separator: "\n").last ?? "-")" }
        print("[blockDemo] \(phaseLabel.text ?? "") | \(rates.joined(separator: " ")) | main=\(mainTicks)Hz")
        statsLabel.text = "main-thread display link: \(mainTicks) Hz"
        mainTicks = 0
    }

    /// Every 300 ms: pause or resume, resize, and every fourth step recreate the views.
    private func startLifecycleStress() {
        var step = 0
        lifecycleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                step += 1
                print("[blockDemo] lifecycle step \(step)")
                for cell in self.cells {
                    (cell.view as? RiveUIView)?.isPaused = step % 3 == 0
                }
                self.stageHeight?.constant = step % 2 == 0 ? 300 : 220
                if step % 4 == 0 {
                    self.rebuildStage()
                }
            }
        }
    }

    private func setChurn(_ isOn: Bool) {
        churnTimer?.invalidate()
        guard isOn else { return }
        var value: Float = 0
        churnTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                value = value >= 100 ? 0 : value + 5
                for instance in self.viewModelInstances {
                    instance.setValue(of: NumberProperty(path: "health"), to: value)
                }
            }
        }
    }

    private func run(_ load: Load) {
        runID += 1
        let id = runID
        let start = CACurrentMediaTime()
        let label = load.title
        phase("idle (before)", id: id)
        print("[blockDemo] t=0 idle start=\(start)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, runID == id else { return }
            phase(label, id: id)
            print("[blockDemo] t=\(CACurrentMediaTime() - start) \(label)")
            block(load, until: CACurrentMediaTime() + load.duration, id: id) { [weak self] in
                guard let self else { return }
                phase("idle (after)", id: id)
                print("[blockDemo] t=\(CACurrentMediaTime() - start) idle after")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.phase("done", id: id)
                    print("[blockDemo] t=\(CACurrentMediaTime() - start) done")
                }
            }
        }
    }

    private func block(_ load: Load, until end: CFTimeInterval, id: Int, completion: @escaping () -> Void) {
        guard runID == id else { return }
        guard CACurrentMediaTime() < end else {
            completion()
            return
        }
        let spinEnd = CACurrentMediaTime() + load.busy
        while CACurrentMediaTime() < spinEnd {}
        DispatchQueue.main.asyncAfter(deadline: .now() + load.free) { [weak self] in
            self?.block(load, until: end, id: id, completion: completion)
        }
    }

    private func phase(_ text: String, id: Int) {
        guard runID == id else { return }
        phaseLabel.text = text
    }

    private func button(_ title: String, action: @escaping () -> Void) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        return UIButton(configuration: configuration, primaryAction: UIAction { _ in action() })
    }

    private func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        return label
    }
}
