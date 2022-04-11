//
//  ExampleStateMachineView.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/12/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct RiveComponents: DismissableView {
    
    /// lets UIKit bind to this to trigger dismiss events
    var dismiss: () -> Void = {}
    
    /// Plays or pauses the button's Rive animation
    @State var play: Bool = false
    
    /// Tracks the health value coming from the slide for the progress bar
    @State var health: Double = 0
    
    @State var sliderController: RiveController = RiveController()
    
    var slider = RViewModel.riveslider
    var bird = RViewModel(RModel(fileName: "bird", stateMachineName: "State Machine 1"))
    var rswitch = RViewModel(RModel(fileName: "switch"))
    
    // TODO: Some views don't display in a ScrollView
    // - The bird and slider don't display
    // - The switch does
    
    var body: some View {
        ScrollView {
            VStack {
                bird.view
                    .frame(width: 500, height: 500, alignment: .center)
                
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
                    
                    // Just a quick hack switch made with the new components
                    rswitch.view
                        .onTapGesture {
                            rswitch.stop()
                            try? rswitch.play(animationName: "On")
                        }
                }
                VStack {
                    Text("RiveProgressBar:")
                    RiveProgressBar(resource: "energy_bar_example", controller: sliderController)
                }
                VStack {
                    Text("New - RiveSlider")
                    slider.view
                }
                
                Slider(value: Binding(get: {
                    self.health
                }, set: { (newVal) in
                    self.health = newVal
                    try? self.sliderController.setNumberState(
                        "State Machine ",
                        inputName: "Energy",
                        value: Float(newVal)
                    )
                    
                    try? slider.setInput("FillPercent", value: newVal)
                }), in: 0...100)
                .padding()
            }
        }
    }
}

 
struct ExampleStateMachineView_Previews: PreviewProvider {
    static var previews: some View {
        RiveComponents()
    }
}
