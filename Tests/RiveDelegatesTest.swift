//
//  RiveDelegatesTest.swift
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 12/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

func getRiveFile(resourceName: String, resourceExt: String=".riv") -> RiveFile {
    
//    bundle.resourceURL
    guard let url = Bundle(for: DelegatesTest.self).url(forResource: resourceName, withExtension: resourceExt) else {
        fatalError("Failed to locate \(resourceName) in bundle.")
    }
    guard var data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    let bytes = [UInt8](data)
    
    return data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer)->RiveFile in
        guard let rawPointer = riveBytes.baseAddress else {
            fatalError("File pointer is messed up")
        }
        let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
        
        guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
            fatalError("Failed to import \(url).")
        }
        return riveFile
    }
}

class MrDelegate: LoopDelegate, PlayDelegate, PauseDelegate, StopDelegate, StateChangeDelegate {
    var plays = [String]()
    var pauses = [String]()
    var stops = [String]()
    var loops = [String]()
    var states = [String]()
    
    func loop(_ animationName: String, type: Int) {
        loops.append(animationName)
    }
    
    func play(_ animationName: String) {
        plays.append(animationName)
    }
    
    func pause(_ animationName: String) {
        pauses.append(animationName)
    }
    
    func stop(_ animationName: String) {
        stops.append(animationName)
    }
    
    func stateChange(_ stateName: String) {
        states.append(stateName)
    }
    
    
}

class DelegatesTest: XCTestCase {
    func testPlay(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playDelegate: delegate
        )
        view.play(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.plays.count, 1)
    }
    
    func testPlayTwice(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            playDelegate: delegate
        )
        view.play(animationName: "one")
        view.play(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.plays.count, 2)
    }
    
    func testPause(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            pauseDelegate: delegate
        )
        view.play(animationName: "one")
        view.pause(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.pauses.count, 1)
    }
    
    func testPauseWhenNotPlaying(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            pauseDelegate: delegate
        )
        view.pause(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.pauses.count, 0)
    }
    
    func testStop(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            stopDelegate: delegate
        )
        view.play(animationName: "one")
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.stops.count, 1)
    }
    
    func testStopNotMounted(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            stopDelegate: delegate
        )
        
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.stops.count, 0)
    }
    
    func testStopPaused(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            stopDelegate: delegate
        )
        view.play(animationName: "one")
        view.pause(animationName: "one")
        view.stop(animationName: "one")
        view.advance(delta:0)
        XCTAssertEqual(delegate.stops.count, 1)
    }
        
    func testLoopOneShot(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            loopDelegate: delegate,
            playDelegate: delegate,
            pauseDelegate: delegate,
            stopDelegate: delegate
        )
        
        view.play(animationName: "one", loop: .loopOneShot)
        view.advance(delta:Double(view.animations.first!.animation().effectiveDurationInSeconds()+0.1))
        // rough. we need an extra advance to flush the stop.
        view.advance(delta:0.1)
        
        XCTAssertEqual(delegate.loops.count, 0)
        XCTAssertEqual(delegate.plays.count, 1)
        XCTAssertEqual(delegate.pauses.count, 0)
        XCTAssertEqual(delegate.stops.count, 1)
    }
    
    func testLoopLoop(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            loopDelegate: delegate,
            playDelegate: delegate,
            pauseDelegate: delegate,
            stopDelegate: delegate
        )
        
        view.play(animationName: "one", loop: .loopLoop)
        view.advance(delta:Double(view.animations.first!.animation().effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.plays.count, 1)
        XCTAssertEqual(delegate.pauses.count, 0)
        XCTAssertEqual(delegate.stops.count, 0)
    }
    
    func testLoopPingPong(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"multiple_animations"),
            autoplay: false,
            loopDelegate: delegate,
            playDelegate: delegate,
            pauseDelegate: delegate,
            stopDelegate: delegate
        )
        
        view.play(animationName: "one", loop: .loopPingPong)
        view.advance(delta:Double(view.animations.first!.animation().effectiveDurationInSeconds()+0.1))
        
        XCTAssertEqual(delegate.loops.count, 1)
        XCTAssertEqual(delegate.plays.count, 1)
        XCTAssertEqual(delegate.pauses.count, 0)
        XCTAssertEqual(delegate.stops.count, 0)
    }
    
    func testStateMachineLayerStates(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"what_a_state"),
            stateMachine: "State Machine 2",
            stateChangeDelegate: delegate
        )
    
        view.advance(delta:0.1)
        XCTAssertEqual(delegate.states.count, 1)
        XCTAssertEqual(delegate.states[0], "go right")
        view.advance(delta:1.1)
        XCTAssertEqual(delegate.states.count, 2)
        XCTAssertEqual(delegate.states[1], "ExitState")
    }
    
    func testStateMachineLayerStatesComplex(){
        let delegate = MrDelegate()
        let view = RiveView.init(
            riveFile: getRiveFile(resourceName:"what_a_state"),
            stateMachine: "State Machine 1",
            stateChangeDelegate: delegate
        )
    
        view.advance(delta:0.0)
        XCTAssertEqual(delegate.states.count, 0)
        
        // lets just start, expect 1 change.
        view.fireState("State Machine 1", inputName: "right")
        // TODO: looks like we got a bit of a bug here. if we do not call this advance,
        // the first animation doesnt seem to get the delta applied. i think its all because of
        // how the 
        view.advance(delta:0.0)
        view.advance(delta:0.4)
        XCTAssertEqual(delegate.states.count, 1)
        XCTAssertEqual(delegate.states[0], "go right")
        delegate.states.removeAll()
        
        
        // should be in same animation still. no state change
        view.advance(delta:0.4)
        XCTAssertEqual(0, delegate.states.count)
        XCTAssertEqual(true, view.isPlaying)

        // animation came to an end inside this time period, this still means no state change
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.states.count)

        // animation is just kinda stuck there. no change no happening.
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.states.count)

        // ok lets change thigns up again.
        view.fireState("State Machine 1", inputName: "change")
        view.advance(delta:0.0)
        view.advance(delta:0.4)
        XCTAssertEqual(true, view.isPlaying)
        XCTAssertEqual(1, delegate.states.count)
        
        XCTAssertEqual("change!", delegate.states[0])
        delegate.states.removeAll()

        // as before lets advance inside the animation -> no change
        view.advance(delta:0.4)
        XCTAssertEqual(true, view.isPlaying)
        XCTAssertEqual(0, delegate.states.count)

        // as before lets advance beyond the end of the animaiton, in this case change to exit!
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(1, delegate.states.count)
        XCTAssertEqual("ExitState", delegate.states[0])
        delegate.states.removeAll()

        // chill on exit. no change.
        view.advance(delta:0.4)
        XCTAssertEqual(false, view.isPlaying)
        XCTAssertEqual(0, delegate.states.count)
    }
}
