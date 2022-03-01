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
                RiveProgressBar(resource: "liquid", health: $health)
            }
            Slider(
                value: $health,
                in: 0...100
            )
            .padding()
        }
    }
}

 
struct ExampleStateMachineView_Previews: PreviewProvider {
    static var previews: some View {
        RiveComponents()
    }
}
