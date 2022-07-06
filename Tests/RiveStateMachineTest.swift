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
}
