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
    private let inputHandler: InputHandler
    private let boundsProvider: () -> CGSize
    private var lastTimestamp: TimeInterval?
    private var hasProcessedFirstDraw = false
    private var wasOnscreen = false

    // MARK: Testing
    #if TESTING
    var onIsSettledChangedForTesting: ((Bool) -> Void)?
    #endif

    // MARK: -

    init(
        rive: Rive,
        boundsProvider: @escaping () -> CGSize,
    ) {
        RiveLog.debug(tag: .view, "[RiveUIView] Initializing controller")
        self.rive = rive
        self.boundsProvider = boundsProvider
        self.inputHandler = InputHandler(
            dependencies: .init(
                commandQueue: rive.file.worker.dependencies.workerService.dependencies.commandQueue
            )
        )

        setupSubscriptions()
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
         | Paused && hasProcessedFirstDraw                       | No                               | No    |
         | Settled && !becameOnscreen && !first frame            | No                               | No    |
         | Unsettled && offscreen && !first frame                | Yes                              | No    |
         | Unsettled && onscreen                                 | Yes                              | Yes   |
         | Settled && becameOnscreen                             | No                               | Yes   |
         */
        // Track visibility transitions so settled views can redraw once when they return onscreen.
        let becameOnscreen = wasOnscreen == false && isOnscreen
        defer { wasOnscreen = isOnscreen }

        // Once paused and already drawn, we can stop producing render work.
        if isPaused, hasProcessedFirstDraw {
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
        }

        if isSettled {
            // Settled views do not animate, but we still allow:
            // 1) one bootstrap draw, and
            // 2) one redraw when transitioning back onscreen.
            if hasProcessedFirstDraw, becameOnscreen == false {
                RiveLog.trace(tag: .view, "[RiveUIView] Skipping frame: settled with no onscreen transition")
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

        return configuration
    }

    // MARK: - Private

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
                    let bounds = boundsProvider()
                    rive.artboard.setSize(bounds)
                } else {
                    RiveLog.debug(tag: .view, "[RiveUIView] Resetting artboard size for non-layout fit")
                    rive.artboard.resetSize()
                }
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
        Task { @MainActor in
            for await _ in stateMachine.settledStream() {
                subject.send(())
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }

    private func dirtyPublisher(for instance: ViewModelInstance) -> AnyPublisher<Void, Never> {
        let subject = PassthroughSubject<Void, Never>()
        Task { @MainActor in
            for await _ in instance.dirtyStream() {
                subject.send(())
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }
}
