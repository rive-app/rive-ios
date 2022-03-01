//
//  LoopMode.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftLoopMode: View {
    let riveView = try!RiveView(resource: "loopy", autoplay: false)
    var direction = Direction.directionAuto
    
    var body: some View {
        ScrollView{
            VStack {
                RiveViewSwift(
                    riveView: riveView
                ).frame(height:300)
                HStack{
                    Button("Reset", action:{try! riveView.reset()})
//                    TODO: work out direction controls
//                    Button("Forwards", action:{direction = .directionForwards})
//                    Button("Auto", action:{direction = .directionAuto})
//                    Button("Backwards", action:{direction = .directionBackwards})
                }
                
            }
            HStack{
                Text("Animation oneshot")
                Button(
                    "Play",
                    action:{try! riveView.play(animationName: "oneshot")}
                )
                Button(
                    "OneShot",
                    action:{try! riveView.play(animationName: "oneshot", loop:.loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try! riveView.play(animationName: "oneshot", loop:.loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try! riveView.play(animationName: "oneshot", loop:.loopPingPong)}
                )
            }
            HStack{
                Text("Animation loop")
                Button(
                    "Play",
                    action:{try! riveView.play(animationName: "loop")}
                )
                Button(
                    "OneShot",
                    action:{try! riveView.play(animationName: "loop", loop:.loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try! riveView.play(animationName: "loop", loop:.loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try! riveView.play(animationName: "loop", loop:.loopPingPong)}
                )
            }
            HStack{
                Text("Animation pingpong")
                Button(
                    "Play",
                    action:{try! riveView.play(animationName: "pingpong")}
                )
                Button(
                    "OneShot",
                    action:{try! riveView.play(animationName: "pingpong", loop:.loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try! riveView.play(animationName: "pingpong", loop:.loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try! riveView.play(animationName: "pingpong", loop:.loopPingPong)}
                )
            }
        }
    }
}

