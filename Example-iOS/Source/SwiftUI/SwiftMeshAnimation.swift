//
//  SwiftMeshAnimation.swift
//  RiveExample
//
//  Created by Zach Plata on 3/11/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftMeshAnimation: View {
    let controller = RiveController();
    @State var isTapped: Bool = false
    
    var body: some View {
        RiveViewSwift(
            resource: "prop_example",
            stateMachine: "State Machine 1",
            controller: controller
        ).frame(height:200)
            .onTapGesture {
                isTapped = !isTapped
                try? self.controller.setBooleanState("State Machine 1", inputName: "Hover", value: isTapped)
            }
            
    }
}
