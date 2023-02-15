//
//  RiveViewModelTest.swift
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 14/02/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

class RiveViewModelTest: XCTestCase {
    
    // This test reproduces a previous production error
    // Having an Animation state without an animation caused advancing a state machine past it
    // to fail
    func testLoadFileWithEmptyAnimationState() throws {
        let file = try RiveFile(testfileName: "empty_animation_state")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        
        view.advance(delta: 0.1)
    }
}
