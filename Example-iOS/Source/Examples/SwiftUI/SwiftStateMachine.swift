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
    var dismiss: () -> Void = {}
    
    // MARK: RiveViewModel
    // This view model specifies the exact StateMachine that it wants from the file
    
    var stateChanger = RiveViewModel(fileName: "skills", stateMachineName: "Designer's Test")
    
    var body: some View {
        ScrollView{
            VStack {
                stateChanger.view()
                    .frame(height:200)
                
                HStack{
                    Button("Beginner") {
                        stateChanger.setInput("Level", value: 0.0)
                    }
                    Button("Intermediate") {
                        stateChanger.setInput("Level", value: 1.0)
                    }
                    Button("Expert") {
                        stateChanger.setInput("Level", value: 2.0)
                    }
                }
                
            }
        }
    }
}

