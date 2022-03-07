//
//  ExampleStateMachineView.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/12/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct RiveComponents: View {
    
    /// lets UIKit bind to this to trigger dismiss events
    var dismiss: () -> Void = {}
    
    /// Plays or pauses the button's Rive animation
    @State var play: Bool = false
    
    /// Tracks the health value coming from the slide for the progress bar
    @State var health: Double = 100
    
    @State var sliderController: RiveController = RiveController()
    
    var body: some View {
        VStack {
            HStack {
                Text("RiveButton:")
                RiveButton(resource: "pull") {
                    print("Button tapped")
                }
            }
            HStack {
                Text("RiveSwitch:")
                RiveSwitch(resource: "switch") { on in
                    print("switch is \(on ? "on" : "off")")
                }
            }
            VStack {
                Text("RiveProgressBar:")
                RiveProgressBar(resource: "life_bar", controller: sliderController, health: $health)
            }
//            Slider(
//                value: $health,
//                in: 0...100
//            )
            Slider(value: Binding(get: {
                self.health
            }, set: { (newVal) in
                self.health = newVal
                print(newVal)
                try? self.sliderController.setBooleanState("Life Machine", inputName: "100", value: true)
                try? self.sliderController.setBooleanState("Life Machine", inputName: "75", value: newVal < 100)
                try? self.sliderController.setBooleanState("Life Machine", inputName: "50", value: newVal <= 66)
                try? self.sliderController.setBooleanState("Life Machine", inputName: "25", value: newVal <= 33)
                try? self.sliderController.setBooleanState("Life Machine", inputName: "0", value: newVal <= 0)
            }), in: 0...100)
            .padding()
        }
    }
}

 
struct ExampleStateMachineView_Previews: PreviewProvider {
    static var previews: some View {
        RiveComponents()
    }
}
