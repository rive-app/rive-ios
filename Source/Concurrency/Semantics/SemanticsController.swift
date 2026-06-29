//
//  SemanticsController.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/5/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

// MARK: - Semantics

/// Controls the VoiceOver accessibility integration mode for a Rive view.
public enum Semantics {
    /// Accessibility semantics are disabled. No accessibility elements are
    /// created regardless of VoiceOver state.
    case off
    /// Accessibility semantics are always active. Elements are created and
    /// kept up-to-date on every frame.
    case on
    /// Accessibility semantics activate and deactivate automatically based
    /// on whether VoiceOver is currently running.
    case automatic
}

// MARK: - UIAccessibilityProtocol

protocol UIAccessibilityProtocol {
    static var isVoiceOverRunning: Bool { get }
    static func post(notification: UIAccessibility.Notification, argument: Any?)
}

extension UIAccessibility: UIAccessibilityProtocol {}

// MARK: - NotificationCenterProtocol

protocol NotificationCenterProtocol {
    func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping @Sendable (Notification) -> Void) -> any NSObjectProtocol
    func removeObserver(_ observer: Any)
}

extension NotificationCenter: NotificationCenterProtocol {}

// MARK: - SemanticsControllerDelegate

/// Delegate for events that require interaction with the hosting view or render loop.
@MainActor
protocol SemanticsControllerDelegate: AnyObject {
    /// Wakes the render loop so the next frame can drain queued semantic diffs.
    func semanticsControllerDidRequestWake(_ controller: SemanticsController)
    /// Called when semantics are enabled for the first time on the state machine.
    func semanticsControllerDidEnableSemantics(_ controller: SemanticsController)
    /// Notifies the delegate that the modal accessibility state changed.
    /// Returns `true` if the modal state transitioned (entered or exited).
    func semanticsController(_ controller: SemanticsController, didUpdateModalState isModal: Bool) -> Bool
    /// Returns the view that owns the accessibility elements (typically the ``RiveUIView``).
    func accessibilityContainerForSemanticsController(_ controller: SemanticsController) -> AnyObject
    /// Returns the current display scale, used to convert pixel bounds to points.
    func displayScaleForSemanticsController(_ controller: SemanticsController) -> CGFloat
}

// MARK: - SemanticsController

/// Orchestrates VoiceOver integration by connecting a ``SemanticsManager``
/// (accessibility tree management) to the ``StateMachine`` (diff source)
/// and UIKit accessibility notifications.
@MainActor
final class SemanticsController {
    struct Dependencies {
        let stateMachine: StateMachine
        let accessibility: UIAccessibilityProtocol.Type
        let notificationCenter: NotificationCenterProtocol
    }

    weak var delegate: SemanticsControllerDelegate?

    var semantics: Semantics = .off {
        didSet {
            guard semantics != oldValue else { return }
            if oldValue == .automatic {
                removeVoiceOverObserver()
            }
            switch semantics {
            case .off:
                stopSemantics()
            case .on:
                if manager == nil { startSemantics() }
            case .automatic:
                addVoiceOverObserver()
                updateSemantics()
            }
        }
    }

    private let dependencies: Dependencies
    private(set) var manager: SemanticsManager?
    private var diffTask: Task<Void, Never>?
    private var voiceOverObserver: (any NSObjectProtocol)?

    #if TESTING
    var onSemanticsDiffProcessedForTesting: (() -> Void)?
    #endif

    var accessibilityElements: [SemanticsElement] {
        if semantics == .off { return [] }
        return manager?.accessibilityElements ?? []
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    deinit {
        diffTask?.cancel()
        if let voiceOverObserver {
            dependencies.notificationCenter.removeObserver(voiceOverObserver)
        }
    }

    func commitDiffs() {
        manager?.commitDiffs()
    }

    func drainDiffs(
        fit: RiveConfigurationFit,
        alignment: RiveConfigurationAlignment,
        scaleFactor: Float,
        viewBounds: CGSize
    ) {
        guard manager != nil else { return }
        dependencies.stateMachine.drainSemanticsDiff(
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            viewBounds: viewBounds
        )
    }

    // MARK: - Private

    private func updateSemantics() {
        guard semantics == .automatic else { return }
        let shouldBeActive = dependencies.accessibility.isVoiceOverRunning
        if shouldBeActive && manager == nil {
            startSemantics()
        } else if !shouldBeActive && manager != nil {
            stopSemantics()
        }
    }

    private func startSemantics() {
        RiveLog.debug(tag: .view, "[RiveUIView] Starting semantics")
        dependencies.stateMachine.enableSemantics()
        manager = SemanticsManager(delegate: self)
        let diffStream = dependencies.stateMachine.semanticsDiffStream().map({ UncheckedSendable(value: $0) })
        diffTask = Task { @MainActor [weak self] in
            for await sendableDiff in diffStream {
                guard let self else { break }
                if Task.isCancelled { break }
                manager?.enqueue(diff: sendableDiff.value)

                #if TESTING
                onSemanticsDiffProcessedForTesting?()
                #endif
            }
        }
        delegate?.semanticsControllerDidEnableSemantics(self)
        delegate?.semanticsControllerDidRequestWake(self)
    }

    private func stopSemantics() {
        RiveLog.debug(tag: .view, "[RiveUIView] Stopping semantics")
        diffTask?.cancel()
        diffTask = nil
        manager = nil
        dependencies.stateMachine.clearSemanticFocus()

        if delegate?.semanticsController(self, didUpdateModalState: false) == true {
            dependencies.accessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    private func addVoiceOverObserver() {
        guard voiceOverObserver == nil else { return }
        voiceOverObserver = dependencies.notificationCenter.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateSemantics()
            }
        }
    }

    private func removeVoiceOverObserver() {
        guard let voiceOverObserver else { return }
        dependencies.notificationCenter.removeObserver(voiceOverObserver)
        self.voiceOverObserver = nil
    }
}

// MARK: - SemanticsController + SemanticsManagerDelegate

extension SemanticsController: SemanticsManagerDelegate {
    func manager(_ manager: SemanticsManager, didRequestFocusForNodeID nodeID: UInt32) {
        dependencies.stateMachine.requestSemanticFocus(nodeID: nodeID)
        delegate?.semanticsControllerDidRequestWake(self)
    }

    func manager(_ manager: SemanticsManager, didFireAction actionType: SemanticActionType, forNodeID nodeID: UInt32) {
        dependencies.stateMachine.fireSemanticAction(nodeID: nodeID, actionType: actionType)
        delegate?.semanticsControllerDidRequestWake(self)
    }

    func managerDidRequestClearFocus(_ manager: SemanticsManager) {
        dependencies.stateMachine.clearSemanticFocus()
        delegate?.semanticsControllerDidRequestWake(self)
    }

    func accessibilityContainerForManager(_ manager: SemanticsManager) -> AnyObject {
        delegate?.accessibilityContainerForSemanticsController(self) ?? NSObject()
    }

    func manager(_ manager: SemanticsManager, didCommitDiffsWithFocusedElement element: SemanticsElement?, isModal: Bool) {
        let modalTransitioned = delegate?.semanticsController(self, didUpdateModalState: isModal) ?? false
        let notification: UIAccessibility.Notification = modalTransitioned ? .screenChanged : .layoutChanged
        dependencies.accessibility.post(notification: notification, argument: element)
    }

    func displayScaleForManager(_ manager: SemanticsManager) -> CGFloat {
        delegate?.displayScaleForSemanticsController(self) ?? 1.0
    }
}

#endif
