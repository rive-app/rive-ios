import XCTest
import UIKit
@testable import RiveRuntime

private class MockTouch: UITouch {
    private let mockLocation: CGPoint

    init(location: CGPoint) {
        self.mockLocation = location
        super.init()
    }

    override func location(in view: UIView?) -> CGPoint {
        return mockLocation
    }
}

class RapidPointerEventTests: XCTestCase {
    var file: RiveFile!

    override func setUp() {
        file = try! RiveFile(testfileName: "rapid_pointer_events")
    }

    override func tearDown() {
        file = nil
    }

    func test_sameFrameDownUp_withoutIntermediateAdvance_skipsDownState() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()
        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        XCTAssertFalse(hasReached.value)

        let stateMachine = model.stateMachine!
        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )

        stateMachine.touchBegan(atLocation: center)
        stateMachine.touchEnded(atLocation: center)
        view.advance(delta: 0)

        XCTAssertFalse(hasReached.value)
    }

    func test_sameFrameDownUp_withIntermediateAdvance_processesDownState() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()
        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        XCTAssertFalse(hasReached.value)

        let stateMachine = model.stateMachine!
        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )

        stateMachine.touchBegan(atLocation: center)
        view.advance(delta: 0)
        XCTAssertTrue(hasReached.value)

        stateMachine.touchEnded(atLocation: center)
        view.advance(delta: 0)
        XCTAssertTrue(hasReached.value)
    }

    func test_flushFollowedByRegularAdvance_doesNotDoubleFire() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()

        let delegate = DrDelegate()
        view.stateMachineDelegate = delegate

        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        var listenerCallCount = 0
        hasReached.addListener { _ in
            listenerCallCount += 1
        }

        let stateMachine = model.stateMachine!
        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )

        stateMachine.touchBegan(atLocation: center)
        view.advance(delta: 0)

        let stateCountAfterFlush = delegate.stateMachineStates.count
        let listenerCountAfterFlush = listenerCallCount
        let eventCountAfterFlush = delegate.events.count

        view.advance(delta: 0.016)

        XCTAssertEqual(delegate.stateMachineStates.count, stateCountAfterFlush,
                       "State changes should not re-fire on the subsequent advance")
        XCTAssertEqual(listenerCallCount, listenerCountAfterFlush,
                       "VMI listener should not re-fire on the subsequent advance")
        XCTAssertEqual(delegate.events.count, eventCountAfterFlush,
                       "Rive events should not re-fire on the subsequent advance")
    }

    // MARK: - Regression

    func test_touchBegan_immediatelyAdvancesStateMachine() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()
        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        XCTAssertFalse(hasReached.value)

        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )
        let touch = MockTouch(location: center)

        view.touchesBegan([touch], with: nil)
        XCTAssertTrue(hasReached.value,
                       "touchesBegan should immediately advance the state machine")
    }

    func test_touchBeganAndEnded_onSameFrame_processesIntermediateState() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()
        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        XCTAssertFalse(hasReached.value)

        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )
        let touch = MockTouch(location: center)

        view.touchesBegan([touch], with: nil)
        XCTAssertTrue(hasReached.value)

        view.touchesEnded([touch], with: nil)
        XCTAssertTrue(hasReached.value)
    }

    func test_touchBegan_doesNotDoubleFireStateChangesOrListeners() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        var vmi: RiveDataBindingViewModel.Instance?
        model.enableAutoBind { vmi = $0 }

        let view = viewModel.createRiveView()

        let delegate = DrDelegate()
        view.stateMachineDelegate = delegate

        view.advance(delta: 0)

        let hasReached = vmi!.booleanProperty(fromPath: "hasReached")!
        var listenerCallCount = 0
        hasReached.addListener { _ in
            listenerCallCount += 1
        }

        let center = CGPoint(
            x: model.artboard.bounds().width / 2,
            y: model.artboard.bounds().height / 2
        )
        let touch = MockTouch(location: center)

        view.touchesBegan([touch], with: nil)

        // The fix should have fired state changes and VMI listeners during touch
        XCTAssertGreaterThan(delegate.stateMachineStates.count, 0,
                             "State changes should fire during touchesBegan")
        XCTAssertGreaterThan(listenerCallCount, 0,
                             "VMI listener should fire during touchesBegan")

        let stateCountAfterTouch = delegate.stateMachineStates.count
        let listenerCountAfterTouch = listenerCallCount

        // Subsequent advances should not re-fire
        view.advance(delta: 0.016)
        view.advance(delta: 0.016)

        XCTAssertEqual(delegate.stateMachineStates.count, stateCountAfterTouch,
                       "State changes should not double-fire after touchesBegan")
        XCTAssertEqual(listenerCallCount, listenerCountAfterTouch,
                       "VMI listener should not double-fire after touchesBegan")
    }
}
