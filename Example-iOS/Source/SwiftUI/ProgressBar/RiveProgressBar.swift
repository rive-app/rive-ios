//
//  RiveProgressBar.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

//struct RiveProgressBar: View {
//
//    let resource: String
//
//    @Binding var health: Double
//
//    var body: some View {
//        VStack {
//            RiveProgressBarBridge(health: $health)
//                .frame(width: 300, height: 75)
//        }
//    }
//}
struct RiveProgressBar: View {
    
    var resource: String = "life_bar"
    var controller: RiveController;
    
    @Binding var health: Double
    
    var body: some View {
        VStack {
            RiveViewSwift(resource: resource, autoplay: true, stateMachine: "Life Machine", controller: controller)
                .frame(width: 300, height: 75)
        }
    }
}


struct RiveProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        RiveProgressBar(resource: "life_bar", controller: RiveController(), health: Binding.constant(50.0))
    }
}
