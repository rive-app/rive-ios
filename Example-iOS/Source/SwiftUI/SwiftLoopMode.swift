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
    let controller = RiveController()
    var direction = Direction.directionAuto
    
    var body: some View {
        ScrollView{
            VStack {
                RiveViewSwift(
                    resource: "loopy", autoplay: false, controller:controller
                ).frame(height:300)
                HStack{
                    Button("Reset", action:{try? controller.reset()})
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
                    action:{try? controller.play("oneshot")}
                )
                Button(
                    "OneShot",
                    action:{try? controller.play("oneshot", .loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try? controller.play("oneshot", .loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try? controller.play("oneshot", .loopPingPong)}
                )
            }
            HStack{
                Text("Animation loop")
                Button(
                    "Play",
                    action:{try? controller.play("loop")}
                )
                Button(
                    "OneShot",
                    action:{try? controller.play("loop", .loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try? controller.play("loop", .loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try? controller.play("loop", .loopPingPong)}
                )
            }
            HStack{
                Text("Animation pingpong")
                Button(
                    "Play",
                    action:{try? controller.play("pingpong")}
                )
                Button(
                    "OneShot",
                    action:{try? controller.play("pingpong", .loopOneShot)}
                )
                Button(
                    "Loop",
                    action:{try? controller.play("pingpong", .loopLoop)}
                )
                Button(
                    "PingPong",
                    action:{try? controller.play("pingpong", .loopPingPong)}
                )
            }
        }
    }
}

