//
//  RiveDelegatesTest.swift
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 12/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

extension RiveFile {
    convenience init(testfileName: String, extension ext: String = ".riv") throws {
        let byteArray = RiveFile.getBytes(fileName: testfileName, extension: ext)
        try self.init(byteArray: byteArray)
    }
    
    static func getBytes(fileName: String, extension ext: String = ".riv") -> [UInt8] {
        guard let url = Bundle(for: DelegatesTest.self).url(forResource: fileName, withExtension: ext) else {
            fatalError("Failed to locate \(fileName) in bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        return [UInt8](data)
    }
}

class DrDelegate: RivePlayerDelegate, RiveStateMachineDelegate {
    var stateMachinePlays = [String]()
    var stateMachinePauses = [String]()
    var stateMachineStops = [String]()
    var linearAnimaitonPlays = [String]()
    var linearAnimaitonPauses = [String]()
    var linearAnimaitonStops = [String]()
    var loops = [String]()
    var stateMachineNames = [String]()
    var stateMachineStates = [String]()
    
    func player(playedWithModel riveModel: RiveModel?) {
        if let stateMachineName = riveModel?.stateMachine?.name() {
            stateMachinePlays.append(stateMachineName)
        }
        else if let animationName = riveModel?.animation?.name() {
            linearAnimaitonPlays.append(animationName)
        }
    }
    
    func player(pausedWithModel riveModel: RiveModel?) {
        if let stateMachineName = riveModel?.stateMachine?.name() {
            stateMachinePauses.append(stateMachineName)
        }
        else if let animationName = riveModel?.animation?.name() {
            linearAnimaitonPauses.append(animationName)
        }
    }
    
    func player(loopedWithModel riveModel: RiveModel?, type: Int) {
        if let stateMachineName = riveModel?.stateMachine?.name() {
            loops.append(stateMachineName)
        }
        else if let animationName = riveModel?.animation?.name() {
            loops.append(animationName)
        }
    }
    
    func player(stoppedWithModel riveModel: RiveModel?) {
        if let stateMachineName = riveModel?.stateMachine?.name() {
            stateMachineStops.append(stateMachineName)
        }
        else if let animationName = riveModel?.animation?.name() {
            linearAnimaitonStops.append(animationName)
        }
    }
    
    func player(didAdvanceby seconds: Double, riveModel: RiveModel?) { }
    
    func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String) {
        stateMachineNames.append(stateMachine.name())
        stateMachineStates.append(stateName)
    }
}

// Technical Note:
// We manually call view.advance(0) in these tests because the results are based on
// messages received by a delegate which is triggered by a timer. We can't wait for
// the timer so we trigger it manually
class DelegatesTest: XCTestCase {
    func testPlay() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one")
        
        // This is necessary because play starts a timer that will eventually get to
        // .advance(n) which triggers the event queue which sends word to the delegate...
        // But the assert happens too fast, so we need to advance manually beforehand.
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
    }
    
    func testPlayTwice() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one")
        viewModel.play(animationName: "one")
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 2)
    }
    
    func testPause() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one")
        viewModel.pause()
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 1)
    }
    
    func testPauseWhenNotPlaying() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.pause()
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
    }
    
    func testStop() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one")
        viewModel.stop()
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
    
    func testStopNotMounted() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, animationName: "one", autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.stop()
        view.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
    
    func testStopPaused() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one")
        viewModel.pause()
        viewModel.stop()
        view.advance(delta: 0)
        viewModel.riveView?.advance(delta: 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
        
    func testLoopOneShot() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one", loop: .oneShot)
        view.advance(delta: Double(viewModel.riveModel!.animation!.effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testLoopLoop() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one", loop: .loop)
        view.advance(delta: Double(viewModel.riveModel!.animation!.effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testLoopPingPong() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "multiple_animations")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        viewModel.play(animationName: "one", loop: .pingPong)
        view.advance(delta: Double(viewModel.riveModel!.animation!.effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testStateMachineLayerStates() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "what_a_state")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, stateMachineName: "State Machine 2", autoPlay: true)
        let view = viewModel.createRiveView()
        
        view.playerDelegate = delegate
        view.stateMachineDelegate = delegate
        
        view.advance(delta:0.1)
        XCTAssertEqual(delegate.stateMachinePlays.count, 1)
        XCTAssertEqual(delegate.stateMachineStates.count, 1)
        XCTAssertEqual(delegate.stateMachineNames[0], "State Machine 2")
        XCTAssertEqual(delegate.stateMachineStates[0], "go right")
        
        view.advance(delta:1.1)
        XCTAssertEqual(delegate.stateMachineStates.count, 2)
        XCTAssertEqual(delegate.stateMachineNames[1], "State Machine 2")
        XCTAssertEqual(delegate.stateMachineStates[1], "ExitState")
        
        // takes an extra advance to trigger
        view.advance(delta:0)
        XCTAssertEqual(delegate.stateMachinePauses.count, 1)
    }
    
    func testStateMachineLayerStatesComplex() throws {
        let delegate = DrDelegate()
        let file = try RiveFile(testfileName: "what_a_state")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, stateMachineName: "State Machine 1", autoPlay: true)
        let view = viewModel.createRiveView()

        view.stateMachineDelegate = delegate
        view.advance(delta:0.0)
        XCTAssertEqual(delegate.stateMachineStates.count, 0)
        viewModel.play()
        // MARK: Input
        // lets just start, expect 1 change.
        viewModel.triggerInput("right")
        // TODO: looks like we got a bit of a bug here
        // If we do not call this advance, the first animation doesnt seem to get the delta applied.
        view.advance(delta:0.0)
        view.advance(delta:0.4)
        XCTAssertEqual(delegate.stateMachineStates.count, 1)
        XCTAssertEqual(delegate.stateMachineStates[0], "go right")
        XCTAssertEqual(delegate.stateMachineNames.count, 1)
        XCTAssertEqual(delegate.stateMachineNames[0], "State Machine 1")
        delegate.stateMachineStates.removeAll()

        // should be in same animation still. no state change
        view.advance(delta:0.4)
        XCTAssertEqual(0, delegate.stateMachineStates.count)
        XCTAssertEqual(true, viewModel.isPlaying)

        // animation came to an end inside this time period, this still means no state change
        view.advance(delta:0.4)
        XCTAssertEqual(false, viewModel.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // animation is just kinda stuck there. no change no happening.
        view.advance(delta:0.4)
        XCTAssertEqual(false, viewModel.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // MARK: Input
        // ok lets change thigns up again.
        viewModel.triggerInput("change")
        view.advance(delta:0.0)
        view.advance(delta:0.4)
        XCTAssertEqual(true, viewModel.isPlaying)
        XCTAssertEqual(1, delegate.stateMachineStates.count)

        XCTAssertEqual("change!", delegate.stateMachineStates[0])
        delegate.stateMachineStates.removeAll()

        // as before lets advance inside the animation -> no change
        view.advance(delta:0.4)
        XCTAssertEqual(true, viewModel.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // as before lets advance beyond the end of the animaiton, in this case change to exit!
        view.advance(delta:0.4)
        XCTAssertEqual(false, viewModel.isPlaying)
        XCTAssertEqual(1, delegate.stateMachineStates.count)
        XCTAssertEqual("ExitState", delegate.stateMachineStates[0])
        delegate.stateMachineStates.removeAll()

        // chill on exit. no change.
        view.advance(delta:0.4)
        XCTAssertEqual(false, viewModel.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)
    }
}
