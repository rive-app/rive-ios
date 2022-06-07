//
//  SwiftWidgets.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/12/21.
//  Updated by Zachary Duncan on 4/15/22.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftWidgets: DismissableView {
    
    /// lets UIKit bind to this to trigger dismiss events
    var dismiss: () -> Void = {}
    
    /// Tracks the health value coming from the slide for the progress bar
    @State var health: Double = 0
    
    var rslider = RiveSlider()
    var rprogress = RiveProgressBar()
    var rswitch = RiveSwitch()
    
    var body: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    HStack {
                        Text("RiveButton:")
                        RiveButton().view {
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
                        rprogress.view()
                        
                        Slider(value: Binding(
                            get: {
                                health
                            },
                            set: { (newVal) in
                                health = newVal
                                rprogress.progress = health
                            }
                        ), in: 0...100)
                        .padding(.leading).padding(.trailing)
                    }
                    Spacer().padding()
                    
                    HStack {
                        Text("RiveSlider:")
                            .padding()
                        rslider.view()
                    }
                    .padding()
                    Spacer().padding()
                }
            }
            .foregroundColor(.white)
        }
    }
}

struct RiveComponents_Previews: PreviewProvider {
    static var previews: some View {
        SwiftWidgets()
    }
}
