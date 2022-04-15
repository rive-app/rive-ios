//
//  StateMachine.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftStateMachine: DismissableView {
    var stateChanger = RiveViewModel(fileName: "skills", stateMachineName: "Designer's Test")
    var dismiss: () -> Void = {}
    
    var body: some View {
        ScrollView{
            VStack {
                stateChanger.view()
                    .frame(height:200)
                
                HStack{
                    Button("Beginner") {
                        try? stateChanger.setInput("Level", value: 0.0)
                    }
                    Button("Intermediate") {
                        try? stateChanger.setInput("Level", value: 1.0)
                    }
                    Button("Expert") {
                        try? stateChanger.setInput("Level", value: 2.0)
                    }
                }
                
            }
        }
    }
}

