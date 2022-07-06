//
//  RiveStateMachineTest.swift
//  RiveRuntimeTests
//
//  Created by Zachary Duncan on 7/6/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

class RiveStateMachineTest: XCTestCase {
    func testDefaultStateMachine() throws {
        let file = try RiveFile(testfileName: "defaultstatemachine")
        let model = RiveModel(riveFile: file)
        
        // The RiveViewModel is responsible for configuring the model properly
        _ = RiveViewModel(model)
        
        XCTAssertEqual(model.artboard.stateMachineCount(), 3)
        XCTAssertEqual(model.artboard.animationCount(), 1)
        XCTAssertEqual(model.animation, nil)
        XCTAssertEqual(model.stateMachine!.name(), "DefaultSM")
    }
    
    // Checks that in the absence of both a default and specified StateMachine
    func testFallbackDefaultStateMachine() throws {
        let file = try RiveFile(testfileName: "multiple_state_machines")
        let model = RiveModel(riveFile: file)
        
        // The RiveViewModel is responsible for configuring the model properly
        _ = RiveViewModel(model)
        
        XCTAssertEqual(model.artboard.stateMachineCount(), 4)
        XCTAssertEqual(model.artboard.animationCount(), 1)
        
        // There is an Animation in the file but the RiveViewModel
        // prioritizes StateMachines
        XCTAssertEqual(model.animation, nil)
        
        // Some StateMachine was assigned. If there's at least one in
        // the file it will be chosen by index 0
        XCTAssertNotEqual(model.stateMachine, nil)
    }
}
