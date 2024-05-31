//
//  SwiftNestedInputs.swift
//  RiveExample
//
//  Created by Philip Chung on 05/27/2022.
//  Copyright © 2024 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftNestedInputs: DismissableView {
    var dismiss: () -> Void = {}
    
    // MARK: RiveViewModel
    // This view model specifies the exact StateMachine that it wants from the file
    @StateObject private var stateChanger = RiveViewModel(fileName: "runtime_nested_inputs", stateMachineName: "MainStateMachine")
    
    var body: some View {
        ScrollView{
            VStack {
                stateChanger.view()
                    .frame(height:200)
                
                VStack{
                    Button("Outer Circle on") {
                        stateChanger.setInput("CircleOuterState", value: true, path: "CircleOuter")
                    }
                    Button("Outer Circle off") {
                        stateChanger.setInput("CircleOuterState", value: false, path: "CircleOuter")
                    }
                    Button("Inner Circle on") {
                        stateChanger.setInput("CircleInnerState", value: true, path: "CircleOuter/CircleInner")
                    }
                    Button("Inner Circle off") {
                        stateChanger.setInput("CircleInnerState", value: false, path: "CircleOuter/CircleInner")
                    }
                }
                
            }
        }
    }
}

