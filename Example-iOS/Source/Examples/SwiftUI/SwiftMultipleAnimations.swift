//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

/// This shows how to utilize one animation file to show content in different artboards and
/// different animations within those artboards
struct SwiftMultipleAnimations: DismissableView {
    var dismiss: () -> Void = {}
    let file = try! RiveFile(name: "artboard_animations")

    var body: some View {
        ScrollView{
            VStack {
                Text("Square - go around")
                RiveViewModel(model(file: file), animationName: "goaround", artboardName: "Square").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Square - roll around")
                RiveViewModel(model(file:file), animationName: "rollaround", artboardName: "Square").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Circle")
                RiveViewModel(model(file:file), artboardName: "Circle").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Star")
                RiveViewModel(model(file:file), artboardName: "Star").view()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
    
    func model(file: RiveFile) -> RiveModel { RiveModel(riveFile: file) }
}
