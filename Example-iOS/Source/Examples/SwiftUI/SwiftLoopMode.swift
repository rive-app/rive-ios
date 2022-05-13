//
//  LoopMode.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftLoopMode: DismissableView {
    var dismiss: () -> Void = {}
    
    var loopy = RiveViewModel(fileName: "loopy", autoPlay: false)
    
    var body: some View {
        ScrollView {
            VStack {
                loopy.view()
                    .frame(height:300)
                HStack {
                    Button("Reset") {
                        try? loopy.reset()
                    }
                }
                
            }
            HStack {
                Text("Spin")
                Button("Play") {
                    try? loopy.play(animationName: "oneshot")
                }
                Button("OneShot") {
                    try? loopy.play(animationName: "oneshot", loop: .loopOneShot)
                }
                Button("Loop") {
                    try? loopy.play(animationName: "oneshot", loop: .loopLoop)
                }
                Button("PingPong") {
                    try? loopy.play(animationName: "oneshot", loop: .loopPingPong)
                }
            }
            HStack {
                Text("Vertical")
                Button("Play") {
                    try? loopy.play(animationName: "loop")
                }
                Button("OneShot") {
                    try? loopy.play(animationName: "loop", loop: .loopOneShot)
                }
                Button("Loop") {
                    try? loopy.play(animationName: "loop", loop: .loopLoop)
                }
                Button("PingPong") {
                    try? loopy.play(animationName: "loop", loop: .loopPingPong)
                }
            }
            HStack {
                Text("Horizontal")
                Button("Play") {
                    try? loopy.play(animationName: "pingpong")
                }
                Button("OneShot") {
                    try? loopy.play(animationName: "pingpong", loop: .loopOneShot)
                }
                Button("Loop") {
                    try? loopy.play(animationName: "pingpong", loop: .loopLoop)
                }
                Button("PingPong") {
                    try? loopy.play(animationName: "pingpong", loop: .loopPingPong)
                }
            }
        }
    }
}

