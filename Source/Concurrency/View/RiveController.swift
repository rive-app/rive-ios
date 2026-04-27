//
//  RiveController.swift
//  RiveRuntime
//
//  Created by Cursor Assistant on 2/20/26.
//

import Foundation
import Combine

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
            if isSettled {
                // This will cause the initial advance on next play to be 0.
                resetTiming()
            }

            #if TESTING
            onIsSettledChangedForTesting?(isSettled)
            #endif
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var settledStreamTask: Task<Void, Never>?
    private var dirtyStreamTask: Task<Void, Never>?
    private let inputHandler: InputHandler
    private let messageGate: CommandQueueMessageGate
    // Optional returns let callers capture the provider with `[weak self]`
    // without a call-site fallback. The controller resolves nil to a
    // deterministic default below (`.zero` / `FallbackScaleProvider`), which
    // also makes both fallbacks unit-testable.
    private let drawableSizeProvider: () -> CGSize?
    private let scaleProvider: () -> ScaleProvider?
    private var lastTimestamp: TimeInterval?
    private var hasProcessedFirstDraw = false
    private var wasOnscreen = false
    private var lastDrawnDrawableSize: CGSize?

    // MARK: Testing
    #if TESTING
    var onIsSettledChangedForTesting: ((Bool) -> Void)?
    #endif

    // MARK: -

    init(
        rive: Rive,
        drawableSizeProvider: @escaping () -> CGSize?,
        scaleProvider: @escaping () -> ScaleProvider?,
    ) {
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing controller")
        self.rive = rive
        self.drawableSizeProvider = drawableSizeProvider
        self.scaleProvider = scaleProvider
        self.messageGate = rive.file.worker.dependencies.workerService.messageGate
        self.inputHandler = InputHandler(
            dependencies: .init(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue
            )
        )

        setupSubscriptions()
    }

    deinit {
        settledStreamTask?.cancel()
        dirtyStreamTask?.cancel()
    }

    func handleInput(_ input: Input) {
        RiveLog.trace(tag: .view, "[RiveUIView] Handling input event")
        inputHandler.handle(input, in: rive.stateMachine)
        isSettled = false
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
                delta = now - lastTimestamp
            } else {
                delta = 0
            }
            lastTimestamp = now
        }

        let shouldAdvance = hasProcessedFirstDraw == false || isSettled == false
        if shouldAdvance {
            RiveLog.trace(tag: .view, "[RiveUIView] Advancing state machine (dt=\(delta))")
            rive.stateMachine.advance(by: delta)
            let hasActiveListeners = rive.stateMachine.hasActiveListeners
                || (rive.viewModelInstance?.hasActiveListeners ?? false)
            messageGate.processMessagesForFrame(hasActiveListeners: hasActiveListeners)
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

    func applyCurrentFit() {
        if case .layout = rive.fit {
            // Use the drawable (pixel) size, matching the advance path.
            // `CommandQueue::setArtboardSize` divides by scale on the C++ side,
            // so the caller must provide pixels — not view points — for
            // `.layout(.automatic)` and `.explicit(N)` to size correctly.
            let drawableSize = drawableSizeProvider() ?? .zero
            let provider = scaleProvider() ?? FallbackScaleProvider()
            let scale = rive.fit.bridged(from: provider).scaleFactor
            RiveLog.debug(tag: .view, "[RiveUIView] Applying layout fit to artboard size: \(drawableSize) scale: \(scale)")
            rive.artboard.setSize(drawableSize, scale: Float(scale))
        } else {
            RiveLog.debug(tag: .view, "[RiveUIView] Resetting artboard size for non-layout fit")
            rive.artboard.resetSize()
        }
    }

    private func setupSubscriptions() {
        RiveLog.debug(tag: .view, "[RiveUIView] Setting up subscriptions")

        // Catch fit values set before the controller existed (missed by the PassthroughSubject).
        applyCurrentFit()

        rive
            .fitDidChange
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyCurrentFit()
            }
            .store(in: &cancellables)

        let anyFit = rive
            .fitDidChange
            .removeDuplicates()
            .map { _ in return false }
        let anyBackgroundColor = rive
            .backgroundColorDidChange
            .removeDuplicates()
            .map { _ in return false }
        let stateMachineSettled = settledPublisher(for: rive.stateMachine).map { true }
        var settled = stateMachineSettled.merge(with: anyFit, anyBackgroundColor).eraseToAnyPublisher()
        if let viewModelInstance = rive.viewModelInstance {
            let dirty = dirtyPublisher(for: viewModelInstance).map { false }
            settled = settled.merge(with: dirty).eraseToAnyPublisher()
        }

        settled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSettled in
                guard let self else { return }
                RiveLog.trace(tag: .view, "[RiveUIView] Settled state changed: \(isSettled)")
                self.isSettled = isSettled
            }
            .store(in: &cancellables)
    }

    private func settledPublisher(for stateMachine: StateMachine) -> AnyPublisher<Void, Never> {
        let subject = PassthroughSubject<Void, Never>()
        settledStreamTask?.cancel()
        settledStreamTask = Task { @MainActor in
            for await _ in stateMachine.settledStream() {
                if Task.isCancelled { break }
                subject.send(())
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }

    private func dirtyPublisher(for instance: ViewModelInstance) -> AnyPublisher<Void, Never> {
        let subject = PassthroughSubject<Void, Never>()
        dirtyStreamTask?.cancel()
        dirtyStreamTask = Task { @MainActor in
            for await _ in instance.dirtyStream() {
                if Task.isCancelled { break }
                subject.send(())
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }
}

/// Used when a `[weak self]` scale provider has gone away by the time the
/// controller needs to resolve a scale factor. Resolves to 1x, matching the
/// pre-concurrency default.
fileprivate struct FallbackScaleProvider: ScaleProvider {
    var nativeScale: CGFloat? { nil }
    var displayScale: CGFloat { 1 }
}
