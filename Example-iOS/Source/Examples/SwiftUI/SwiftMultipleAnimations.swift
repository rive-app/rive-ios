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
    private let file = try! RiveFile(name: "artboard_animations")
    var dismiss: () -> Void = {}
    
    var body: some View {
        ScrollView{
            VStack {
                Text("Square - go around")
                RiveViewModel(model(), artboardName: "Square", animationName: "goaround").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Square - roll around")
                RiveViewModel(model(), artboardName: "Square", animationName: "rollaround").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Circle")
                RiveViewModel(model(), artboardName: "Circle").view()
                    .aspectRatio(1, contentMode: .fit)
                
                Text("Star")
                RiveViewModel(model(), artboardName: "Star").view()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
    
    func model() -> RiveModel { RiveModel(riveFile: file) }
}
