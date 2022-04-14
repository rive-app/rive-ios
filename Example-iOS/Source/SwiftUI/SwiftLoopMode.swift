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
    
    var loopy = RViewModel(fileName: "loopy", autoplay: false)
//    var direction = Direction.directionAuto
    
    var body: some View {
        ScrollView {
            VStack {
//                RiveViewSwift(
//                    resource: "loopy", autoplay: false, controller:controller
//                )
                
                loopy.view()
                    .frame(height:300)
                HStack {
                    Button("Reset") {
                        try? loopy.reset()
                    }
                    
//                    TODO: work out direction controls
//                    Button("Forwards", action:{direction = .directionForwards})
//                    Button("Auto", action:{direction = .directionAuto})
//                    Button("Backwards", action:{direction = .directionBackwards})
                }
                
            }
            HStack {
                Text("Oneshot")
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
                Text("Loop")
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
                Text("Pingpong")
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

