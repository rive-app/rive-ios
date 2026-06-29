//
//  RiveController.swift
//  RiveRuntime
//
//  Created by Cursor Assistant on 2/20/26.
//

import Foundation
import Combine
#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit
#endif

// MARK: - RiveControllerDelegate

@MainActor
protocol RiveControllerDelegate: AnyObject, ScaleProvider {
    var drawableSize: CGSize { get }
    #if !os(macOS) || RIVE_MAC_CATALYST
    var accessibilityContainer: AnyObject { get }
    func controller(_ controller: RiveController, didUpdateModalState isModal: Bool) -> Bool
    #endif
}

// MARK: - RiveController

@MainActor
final class RiveController {
    let rive: Rive
    var isPaused = false {
        didSet {
            guard oldValue != isPaused else { return }
            if isPaused {
                resetTiming()
            }
        }
    }

    private(set) var isSettled = false {
        didSet {
            guard oldValue != isSettled else { return }

            if isSettled {
                // Nil lastTimestamp so the first advance after re-unsettling
                // starts at delta 0 instead of jumping by the wall-clock
                // time spent settled.
                resetTiming()
            }

            #if TESTING
            onIsSettledChangedForTesting?(isSettled)
            #endif
        }
    }

    private var hasPendingSettle = false
    private var isDirty = false

    private var cancellables = Set<AnyCancellable>()
    private var settledStreamTask: Task<Void, Never>?
    private var dirtyStreamTask: Task<Void, Never>?
    private let inputHandler: InputHandler
    private let messageGate: CommandQueueMessageGate
    private weak var delegate: RiveControllerDelegate?
    private var lastTimestamp: TimeInterval?
    private var hasProcessedFirstDraw = false
    private var wasOnscreen = false
    private var lastDrawnDrawableSize: CGSize?

    #if !os(macOS) || RIVE_MAC_CATALYST
    let semanticsController: SemanticsController

    var semantics: Semantics {
        get { semanticsController.semantics }
        set { semanticsController.semantics = newValue }
    }
    #endif

    // MARK: Testing
    #if TESTING
    var onIsSettledChangedForTesting: ((Bool) -> Void)?
    var onHasPendingSettleForTesting: (() -> Void)?
    #endif

    // MARK: -

    #if !os(macOS) || RIVE_MAC_CATALYST
    init(
        rive: Rive,
        delegate: RiveControllerDelegate,
        accessibility: UIAccessibilityProtocol.Type = UIAccessibility.self,
        notificationCenter: NotificationCenterProtocol = NotificationCenter.default
    ) {
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing controller")
        self.rive = rive
        self.delegate = delegate
        self.messageGate = rive.file.worker.dependencies.workerService.messageGate
        self.inputHandler = InputHandler(
            dependencies: .init(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue
            )
        )

        self.semanticsController = SemanticsController(
            dependencies: .init(
                stateMachine: rive.stateMachine,
                accessibility: accessibility,
                notificationCenter: notificationCenter
            )
        )

        setupSubscriptions()
        semanticsController.delegate = self
    }
    #else
    init(
        rive: Rive,
        delegate: RiveControllerDelegate
    ) {
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing controller")
        self.rive = rive
        self.delegate = delegate
        self.messageGate = rive.file.worker.dependencies.workerService.messageGate
        self.inputHandler = InputHandler(
            dependencies: .init(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue
            )
        )

        setupSubscriptions()
    }
    #endif

    deinit {
        settledStreamTask?.cancel()
        dirtyStreamTask?.cancel()
    }

    func handleInput(_ input: Input) {
        RiveLog.trace(tag: .view, "[RiveUIView] Handling input event")
        inputHandler.handle(input, in: rive.stateMachine)
        markDirty()
    }

    func resetTiming() {
        RiveLog.trace(tag: .view, "[RiveUIView] Resetting frame timing")
        // This will cause the initial advance on next play to be 0.
        lastTimestamp = nil
    }

    func advance(
        now: TimeInterval,
        isOnscreen: Bool,
        drawableSize: CGSize,
        scaleProvider: ScaleProvider
    ) -> RiveUIRendererConfiguration? {
        /*
         | Condition                                             | Advance?                         | Draw? |
         |-------------------------------------------------------|----------------------------------|-------|
         | First frame (hasProcessedFirstDraw == false)          | Yes (always, delta 0)           | Yes   |
         | Paused && hasProcessedFirstDraw && !sizeChanged       | No                               | No    |
         | Settled && !becameOnscreen && !sizeChanged && !first  | No                               | No    |
         | Unsettled && offscreen && !first frame                | Yes                              | No    |
         | Unsettled && onscreen                                 | Yes                              | Yes   |
         | Settled && becameOnscreen                             | No                               | Yes   |
         | Paused && drawable size changed                       | No                               | Yes   |
         | Settled && drawable size changed                      | No                               | Yes   |
         */
        // Track visibility transitions so settled views can redraw once when they return onscreen.
        let becameOnscreen = wasOnscreen == false && isOnscreen
        defer { wasOnscreen = isOnscreen }

        // Track drawable-size changes so settled views can redraw once on resize.
        let drawableSizeChanged = lastDrawnDrawableSize != nil && lastDrawnDrawableSize != drawableSize

        // Apply .layout fit's artboard size on first frame and on resize,
        // passing the resolved layout scale so `.automatic` (Retina / backing
        // scale) and explicit non-unit scale factors size the artboard correctly.
        if case .layout = rive.fit, lastDrawnDrawableSize != drawableSize {
            let fitBridge = rive.fit.bridged(from: scaleProvider)
            rive.artboard.setSize(drawableSize, scale: Float(fitBridge.scaleFactor))
        }

        // Once paused and already drawn, we can stop producing render work —
        // unless the drawable size changed, in which case allow one redraw so
        // the static content re-fits the new bounds without advancing time.
        if isPaused, hasProcessedFirstDraw, drawableSizeChanged == false {
            RiveLog.trace(tag: .view, "[RiveUIView] Skipping frame: paused after first draw")
            return nil
        }

        let delta: TimeInterval
        if isPaused {
            // Paused bootstrap draws should render a frame, but not advance time.
            delta = 0
        } else {
            // Unpaused timing: first frame advances by 0, subsequent frames use timestamp delta.
            if let lastTimestamp {
                // The CACurrentMediaTime() fallback in DisplayLink can
                // slightly overshoot the first real vsync timestamp,
                // producing a small negative delta. Clamp to zero since
                // negative advances are not supported by the C++ runtime.
                delta = max(0, now - lastTimestamp)
            } else {
                delta = 0
            }
            lastTimestamp = now
        }

        #if !os(macOS) || RIVE_MAC_CATALYST
        semanticsController.commitDiffs()
        #endif

        resolvePendingEvents()
        messageGate.processMessagesForFrame()

        let shouldAdvance = hasProcessedFirstDraw == false || isSettled == false
        if shouldAdvance {
            isDirty = false
            RiveLog.trace(tag: .view, "[RiveUIView] Advancing state machine (dt=\(delta))")
            rive.stateMachine.advance(by: delta)

            #if !os(macOS) || RIVE_MAC_CATALYST
            let semanticsFitBridge = rive.fit.bridged(from: scaleProvider)
            semanticsController.drainDiffs(
                fit: semanticsFitBridge.fit,
                alignment: semanticsFitBridge.alignment,
                scaleFactor: Float(semanticsFitBridge.scaleFactor),
                viewBounds: drawableSize
            )
            #endif
        }

        if isSettled {
            // Settled views do not animate, but we still allow:
            // 1) one bootstrap draw,
            // 2) one redraw when transitioning back onscreen, and
            // 3) one redraw when the drawable size changes (resize, scale factor).
            if hasProcessedFirstDraw, becameOnscreen == false, drawableSizeChanged == false {
                RiveLog.trace(tag: .view, "[RiveUIView] Skipping frame: settled with no onscreen transition or resize")
                return nil
            }
        }

        // After the first draw, offscreen frames skip render output.
        if isOnscreen == false, hasProcessedFirstDraw {
            return nil
        }

        // Build renderer configuration only when this frame should be drawn.
        let fitBridge = rive.fit.bridged(from: scaleProvider)
        let configuration = RiveUIRendererConfiguration(
            artboardHandle: rive.artboard.artboardHandle,
            stateMachineHandle: rive.stateMachine.stateMachineHandle,
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            size: drawableSize,
            pixelFormat: MTLRiveColorPixelFormat(),
            layoutScale: fitBridge.scaleFactor,
            color: rive.backgroundColor.argbValue
        )

        hasProcessedFirstDraw = true
        lastDrawnDrawableSize = drawableSize

        return configuration
    }

    // MARK: - Private

    private func markDirty() {
        isDirty = true
        hasPendingSettle = false
        guard isSettled else { return }
        isSettled = false
    }

    private func resolvePendingEvents() {
        guard hasPendingSettle else { return }
        if isDirty {
            isDirty = false
        } else {
            isSettled = true
        }
        hasPendingSettle = false
    }

    #if TESTING
    func resolveForTesting() {
        resolvePendingEvents()
    }
    #endif

    private func setupSubscriptions() {
        RiveLog.debug(tag: .view, "[RiveUIView] Setting up subscriptions")
        rive
            .fitDidChange
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fit in
                guard let self else { return }
                if case .layout = fit {
                    RiveLog.debug(tag: .view, "[RiveUIView] Applying layout fit to artboard size")
                    let drawableSize = delegate?.drawableSize ?? .zero
                    let provider: ScaleProvider = delegate ?? FallbackScaleProvider()
                    let scale = fit.bridged(from: provider).scaleFactor
                    rive.artboard.setSize(drawableSize, scale: Float(scale))
                } else {
                    RiveLog.debug(tag: .view, "[RiveUIView] Resetting artboard size for non-layout fit")
                    rive.artboard.resetSize()
                }
                RiveLog.trace(tag: .view, "[RiveUIView] Settled state changed: false (fit)")
                markDirty()
            }
            .store(in: &cancellables)

        rive
            .backgroundColorDidChange
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                RiveLog.trace(tag: .view, "[RiveUIView] Settled state changed: false (backgroundColor)")
                self.markDirty()
            }
            .store(in: &cancellables)

        // Settled and dirty events are observed directly via @MainActor Tasks
        // rather than bridging through Combine (PassthroughSubject → merge →
        // removeDuplicates → receive(on:) → sink). This eliminates two async
        // hops per event and preserves FIFO ordering on the actor executor.
        //
        // Streams are captured as locals before the Task so that `guard let self`
        // only lives inside each loop iteration — never across the `for await`
        // suspension — avoiding a retain cycle between the Task and the controller.
        settledStreamTask?.cancel()
        let settledStream = rive.stateMachine.settledStream()
        settledStreamTask = Task { @MainActor [weak self] in
            for await _ in settledStream {
                guard let self else { break }
                if Task.isCancelled { break }
                hasPendingSettle = true
                #if TESTING
                onHasPendingSettleForTesting?()
                #endif
            }
        }

        if let viewModelInstance = rive.viewModelInstance {
            dirtyStreamTask?.cancel()
            let dirtyStream = viewModelInstance.dirtyStream()
            dirtyStreamTask = Task { @MainActor [weak self] in
                for await _ in dirtyStream {
                    guard let self else { break }
                    if Task.isCancelled { break }
                    markDirty()
                }
            }
        }
    }
}

/// Used when a `[weak self]` scale provider has gone away by the time the
/// controller needs to resolve a scale factor. Resolves to 1x, matching the
/// pre-concurrency default.
fileprivate struct FallbackScaleProvider: ScaleProvider {
    var nativeScale: CGFloat? { nil }
    var displayScale: CGFloat { 1 }
}

// MARK: - RiveController + SemanticsControllerDelegate

#if !os(macOS) || RIVE_MAC_CATALYST
extension RiveController: SemanticsControllerDelegate {
    func semanticsControllerDidRequestWake(_ controller: SemanticsController) {
        markDirty()
    }

    func semanticsControllerDidEnableSemantics(_ controller: SemanticsController) {
        guard let delegate else { return }
        let fitBridge = rive.fit.bridged(from: delegate)
        controller.drainDiffs(
            fit: fitBridge.fit,
            alignment: fitBridge.alignment,
            scaleFactor: Float(fitBridge.scaleFactor),
            viewBounds: delegate.drawableSize
        )
    }

    func semanticsController(_ controller: SemanticsController, didUpdateModalState isModal: Bool) -> Bool {
        delegate?.controller(self, didUpdateModalState: isModal) ?? false
    }

    func accessibilityContainerForSemanticsController(_ controller: SemanticsController) -> AnyObject {
        delegate?.accessibilityContainer ?? NSObject()
    }

    func displayScaleForSemanticsController(_ controller: SemanticsController) -> CGFloat {
        delegate?.displayScale ?? 1.0
    }
}
#endif
