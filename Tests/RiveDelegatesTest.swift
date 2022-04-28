//
//  RiveDelegatesTest.swift
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 12/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

func getBytes(resourceName: String, resourceExt: String=".riv") -> [UInt8] {
    guard let url = Bundle(for: DelegatesTest.self).url(forResource: resourceName, withExtension: resourceExt) else {
        fatalError("Failed to locate \(resourceName) in bundle.")
    }
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    return [UInt8](data)
}

func getRiveFile(resourceName: String, resourceExt: String=".riv") throws -> RiveFile {
    let byteArray = getBytes(resourceName: resourceName, resourceExt: resourceExt)
    let riveFile = try RiveFile(byteArray: byteArray)
    return riveFile
}

class MrDelegate: RivePlayerDelegate, RStateDelegate {
    var stateMachinePlays = [String]()
    var stateMachinePauses = [String]()
    var stateMachineStops = [String]()
    var linearAnimaitonPlays = [String]()
    var linearAnimaitonPauses = [String]()
    var linearAnimaitonStops = [String]()
    var loops = [String]()
    var stateMachineNames = [String]()
    var stateMachineStates = [String]()
    
    func loop(animation animationName: String, type: Int) {
        loops.append(animationName)
    }
    
    func play(animation animationName: String, isStateMachine: Bool) {
        if (isStateMachine){
            stateMachinePlays.append(animationName)
        }
        else {
            linearAnimaitonPlays.append(animationName)
        }
        
    }
    
    func pause(animation animationName: String, isStateMachine: Bool) {
        if (isStateMachine){
            stateMachinePauses.append(animationName)
        }
        else {
            linearAnimaitonPauses.append(animationName)
        }
    }
    
    func stop(animation animationName: String, isStateMachine: Bool) {
        if (isStateMachine){
            stateMachineStops.append(animationName)
        }
        else {
            linearAnimaitonStops.append(animationName)
        }
        
    }
    
    func stateChange(_ stateMachineName:String, _ stateName: String) {
        stateMachineNames.append(stateMachineName)
        stateMachineStates.append(stateName)
    }
    
    
}

class DelegatesTest: XCTestCase {
    func testPlay() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        try view.play(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
    }
    
    func testPlayTwice() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        try view.play(animationName: "one")
        try view.play(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 2)
    }
    
    func testPause() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        try view.play(animationName: "one")
        view.pause(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 1)
    }
    
    func testPauseWhenNotPlaying() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        view.pause(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
    }
    
    func testStop() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        try view.play(animationName: "one")
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
    
    func testStopNotMounted() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testStopPaused() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        try view.play(animationName: "one")
        view.pause(animationName: "one")
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
        
    func testLoopOneShot() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        
        try view.play(animationName: "one", loop: .loopOneShot)
        view.advance(delta:Double(view.animations.first!.effectiveDurationInSeconds()+0.1))
        // rough. we need an extra advance to flush the stop.
        view.advance(delta:0.1)
        
        XCTAssertEqual(delegate.loops.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 1)
    }
    
    func testLoopLoop() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        
        try view.play(animationName: "one", loop: .loopLoop)
        view.advance(delta:Double(view.animations.first!.effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testLoopPingPong() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playerDelegate: delegate
        )
        
        try view.play(animationName: "one", loop: .loopPingPong)
        view.advance(delta:Double(view.animations.first!.effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPlays.count, 1)
        XCTAssertEqual(delegate.linearAnimaitonPauses.count, 0)
        XCTAssertEqual(delegate.linearAnimaitonStops.count, 0)
    }
    
    func testStateMachineLayerStates() throws {
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"what_a_state"),
            stateMachineName: "State Machine 2",
            playerDelegate: delegate,
            stateChangeDelegate: delegate
        )

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
        let delegate = MrDelegate()
        let view = try RiveView.init(
            riveFile: getRiveFile(resourceName:"what_a_state"),
            stateMachineName: "State Machine 1",
            stateChangeDelegate: delegate
        )
    
        view.advance(delta:0.0)
        XCTAssertEqual(delegate.stateMachineStates.count, 0)
        
        // lets just start, expect 1 change.
        try view.fireState("State Machine 1", inputName: "right")
        // TODO: looks like we got a bit of a bug here. if we do not call this advance,
        // the first animation doesnt seem to get the delta applied. i think its all because of
        // how the 
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
        XCTAssertEqual(true, view.isPlaying)

        // animation came to an end inside this time period, this still means no state change
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // animation is just kinda stuck there. no change no happening.
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // ok lets change thigns up again.
        try view.fireState("State Machine 1", inputName: "change")
        view.advance(delta:0.0)
        view.advance(delta:0.4)
        XCTAssertEqual(true, view.isPlaying)
        XCTAssertEqual(1, delegate.stateMachineStates.count)
        
        XCTAssertEqual("change!", delegate.stateMachineStates[0])
        delegate.stateMachineStates.removeAll()

        // as before lets advance inside the animation -> no change
        view.advance(delta:0.4)
        XCTAssertEqual(true, view.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)

        // as before lets advance beyond the end of the animaiton, in this case change to exit!
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(1, delegate.stateMachineStates.count)
        XCTAssertEqual("ExitState", delegate.stateMachineStates[0])
        delegate.stateMachineStates.removeAll()

        // chill on exit. no change.
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.stateMachineStates.count)
    }
}
