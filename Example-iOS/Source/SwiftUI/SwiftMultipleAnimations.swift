//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftMultipleAnimations: View {
    
    var body: some View {
        ScrollView{
            VStack {
                Text("Square - go around")
                RiveViewSwift(
                    riveView: try! RiveView(
                        resource: "artboard_animations",
                        artboard: "Square",
                        animation:"goaround"
                    )
                ).frame(height:200)
                Text("Square - roll around")
                RiveViewSwift(
                    riveView:try! RiveView(
                        resource: "artboard_animations",
                        artboard: "Square",
                        animation:"rollaround"
                    )
                ).frame(height:200)
                Text("Circle")
                RiveViewSwift(
                    riveView:try! RiveView(
                        resource: "artboard_animations",
                        artboard: "Circle"
                    )
                ).frame(height:200)
                Text("Star")
                RiveViewSwift(
                    riveView:try! RiveView(
                        resource: "artboard_animations",
                        artboard: "Star"
                    )
                ).frame(height:200)
            }
        }
    }
}

