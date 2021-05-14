//
//  ExampleStateMachineView.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/12/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct ExampleStateMachineView: View {
    
    /// lets UIKit bind to this to trigger dismiss events
    var dismiss: () -> Void = {}
    
    /// Plays or pauses the Rive animation
    @State var play: Bool = false
    
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
        }
    }
}






/*

struct ExampleStateMachineView: View {
    @ObservedObject private var riveController = RiveController(
        "skills",
        fit: Fit.Cover
    )
    
    var dismiss: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                controller: riveController
            )
            VStack {
                HStack(alignment: .firstTextBaseline, spacing: 50) {
                    if #available(iOS 14.0, *) {
                        Menu {
                            ForEach(riveController.stateMachineInputs, id: \.self) { input in
                                Button {
                                    // riveController.activeArtboard = name
                                } label: {
                                    Text(input.name)
                                }
                            }
                        } label: {
                            Text("Inputs")
                            Image(systemName: "pencil.circle")
                        }
                    }
                }
                .padding()
                HStack(alignment: .center, spacing: 50) {
                    if #available(iOS 14.0, *) {
                        Menu {
                            ForEach(riveController.artboardNames(), id: \.self) { name in
                                Button {
                                    riveController.activeArtboard = name
                                } label: {
                                    Text(name)
                                }
                            }
                        } label: {
                            Text("Artboards")
                            Image(systemName: "square.and.pencil")
                        }
                        Menu {
                            ForEach(riveController.stateMachineNames(), id: \.self) { name in
                                Button {
                                    riveController.playAnimation = name
                                } label: {
                                    Text(name)
                                }
                            }
                        } label: {
                            Text("Machines")
                            Image(systemName: "list.and.film")
                        }
                    }
                }
                .padding()
                HStack {
                    Button {
                        if riveController.playback == Playback.play {
                            riveController.pause()
                        } else {
                            riveController.play()
                        }
                    } label: {
                        switch riveController.playback {
                        case .play:
                            Image(systemName: "pause.circle")
                            Text("Pause")
                        case .pause, .stop:
                            Image(systemName: "play.circle")
                            Text("Play")
                        }
                    }
                    Spacer()
                    Button(action: dismiss, label: {
                        Image(systemName: "x.circle")
                        Text("Dismiss")
                    })
                }
                .padding()
            }
        }
        .background(Color.init(white: 0, opacity: 0.75))
    }
}

*/
 
struct ExampleStateMachineView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleStateMachineView()
    }
}
