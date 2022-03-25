//
//  RiveProgressBar.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct RiveProgressBar: View {
    
    let resource: String
    var controller: RiveController
    
    var body: some View {
        VStack {
            RiveViewSwift(resource: resource, fit: Binding.constant(.fitCover), autoplay: true, stateMachine: "State Machine ", controller: controller)
                .frame(width: 300, height: 75)
        }
    }
}


struct RiveProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        RiveProgressBar(resource: "energy_bar_example", controller: RiveController())
    }
}

//struct NewProgressBar: View {
//    private let resource = RResource(resource: "energy_bar_example", stateMachine: "State Machine ")
//    
//    init() {
//        
//    }
//    
//    var body: some View {
//        RiveResource(resource)
//    }
//    
//    public func setPosition() {
//        setNumberState("State Machine ", inputName: "Energy", value: Float(newVal))
//    }
//}
//
//extension NewRiveController {
//    fileprivate func setNumberState(_ value: Float) throws {
//        try oldController.setNumberState("State Machine ", inputName: "Energy", value: value)
//    }
//}
