//
//  SwiftTestParityAnimSM.swift
//  RiveExample
//
//  Created by Zachary Duncan on 5/27/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

/// Test to check the difference in behavior between an Animation and an almost idential StateMachine
struct SwiftTestParityAnimSM: DismissableView {
    var dismiss: () -> Void = {}
    
    var body: some View {
        SwiftVMPlayer(
            viewModels:
                RiveViewModel(fileName: "teststatemachine", stateMachineName: "State Machine 1", autoPlay: false),
            RiveViewModel(fileName: "testanimation", animationName: "Move", autoPlay: false)
        )
    }
}
