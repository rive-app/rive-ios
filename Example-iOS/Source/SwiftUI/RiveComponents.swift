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
    
    var slider = RSlider()
    var bird = RViewModel(RModel(fileName: "bird", stateMachineName: "State Machine 1"))
    var rswitch = RSwitch()
    
    var body: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    VStack {
                        Text("Bird Animation")
                        bird.view()
                            .aspectRatio(1, contentMode: .fill)
                    }
                    
                    Spacer().padding()
                    HStack {
                        Text("RButton:")
                        RButton().view {
                            print("Button tapped")
                        }
                    }
                    
                    Spacer().padding()
                    HStack {
                        Text("RSwitch:")
                        rswitch.view { on in
                            print("The switch is " + (on ? "on" : "off"))
                        }
                    }
                    
                    Spacer().padding()
                    VStack {
                        Text("RiveProgressBar:")
                        RiveProgressBar(resource: "energy_bar_example", controller: sliderController)
                            .aspectRatio(1, contentMode: .fill)
                        
                        Slider(value: Binding(get: {
                            self.health
                        }, set: { (newVal) in
                            self.health = newVal
                            try? self.sliderController.setNumberState(
                                "State Machine ",
                                inputName: "Energy",
                                value: Float(newVal)
                            )
                        }), in: 0...100)
                        .aspectRatio(1, contentMode: .fill)
                        .padding()
                    }
                    
                    Spacer().padding()
                    VStack {
                        Text("RiveSlider - Touch Events")
                        slider.view()
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .foregroundColor(.white)
        }
    }
}

struct RiveComponents_Previews: PreviewProvider {
    static var previews: some View {
        RiveComponents()
    }
}
