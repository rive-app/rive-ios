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
    
    func testChangingTextRun_updatesText_andAdvances() throws {
        let file = try RiveFile(testfileName: "testtext")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let delegate = PlayerDelegate()
        let view = viewModel.createRiveView()
        view.playerDelegate = delegate

        XCTAssertEqual(viewModel.getTextRunValue("MyRun"), "Hello there")
        try viewModel.setTextRunValue("MyRun", textValue: "Hello test")
        XCTAssertEqual(viewModel.getTextRunValue("MyRun"), "Hello test")
        XCTAssertTrue(delegate.didAdvance)
    }

    func testChangingNestedTextRun_updatesText_andAdvances() throws {
        let file = try RiveFile(testfileName: "nested_text_run")
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)
        let view = viewModel.createRiveView()
        let delegate = PlayerDelegate()
        view.playerDelegate = delegate

        XCTAssertEqual(viewModel.getTextRunValue("text", path: "Nested/Two-Deep"), "Text")
        try viewModel.setTextRunValue("text", path: "Nested/Two-Deep", textValue: "Hello test")
        XCTAssertEqual(viewModel.getTextRunValue("text", path: "Nested/Two-Deep"), "Hello test")
        XCTAssertTrue(delegate.didAdvance)
    }
}

private extension RiveViewModelTest {
    class PlayerDelegate: NSObject, RivePlayerDelegate {
        var didAdvance = false

        func player(playedWithModel riveModel: RiveRuntime.RiveModel?) { }

        func player(pausedWithModel riveModel: RiveRuntime.RiveModel?) { }

        func player(loopedWithModel riveModel: RiveRuntime.RiveModel?, type: Int) { }

        func player(stoppedWithModel riveModel: RiveRuntime.RiveModel?) { }

        func player(didAdvanceby seconds: Double, riveModel: RiveModel?) {
            didAdvance = true
        }
    }
}
