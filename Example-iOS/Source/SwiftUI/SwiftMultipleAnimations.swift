//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftMultipleAnimations: DismissableView {
    private let fileName = "artboard_animations"
    var dismiss: () -> Void = {}
    
    var body: some View {
        ScrollView{
            VStack {
                Text("Square - go around")
                RViewModel(fileName: fileName, artboardName: "Square", animationName: "goaround").view()
                    .frame(height:200)
                
                Text("Square - roll around")
                RViewModel(fileName: fileName, artboardName: "Square", animationName: "rollaround").view()
                    .frame(height:200)
                
                Text("Circle")
                RViewModel(fileName: fileName, artboardName: "Circle").view()
                    .frame(height:200)
                
                Text("Star")
                RViewModel(fileName: fileName, artboardName: "Star").view()
                    .frame(height:200)
            }
        }
    }
}

