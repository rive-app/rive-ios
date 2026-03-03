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

    // MARK: Testing
    #if TESTING
    var onIsSettledChangedForTesting: ((Bool) -> Void)?
    #endif

    // MARK: -

    init(
        rive: Rive,
        boundsProvider: @escaping () -> CGSize,
    ) {
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
        inputHandler.handle(input, in: rive.stateMachine)
        isSettled = false
    }

    func resetTiming() {
        // This will cause the initial advance on next play to be 0.
        lastTimestamp = nil
    }

    func advance(
        now: TimeInterval,
        isPaused: Bool,
        isOnscreen: Bool,
        drawableSize: CGSize,
        scaleProvider: ScaleProvider
    ) -> RendererConfiguration? {
        if isPaused, hasProcessedFirstDraw {
            return nil
        }

        let delta: TimeInterval
        if isPaused {
            // Paused bootstrap draws should render a frame, but not advance time.
            delta = 0
        } else {
            if let lastTimestamp {
                delta = now - lastTimestamp
            } else {
                delta = 0
            }
            lastTimestamp = now
        }

        guard isSettled == false else {
            return nil
        }

        rive.stateMachine.advance(by: delta)

        guard isOnscreen else {
            return nil
        }

        let fitBridge = rive.fit.bridged(from: scaleProvider)
        let configuration = RendererConfiguration(
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
        rive
            .fitDidChange
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fit in
                guard let self else { return }
                if case .layout = fit {
                    let bounds = boundsProvider()
                    rive.artboard.setSize(bounds)
                } else {
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
