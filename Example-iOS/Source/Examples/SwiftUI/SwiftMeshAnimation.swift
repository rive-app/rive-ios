//
//  SwiftMeshAnimation.swift
//  RiveExample
//
//  Created by Zach Plata on 3/11/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftMeshAnimation: DismissableView {
    var tapePlayer = RiveViewModel(fileName: "prop_example", stateMachineName: "State Machine 1")
    @State var isTapped: Bool = false
    var dismiss: () -> Void = {}
    
    var body: some View {
        tapePlayer.view()
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture {
                isTapped = !isTapped
                try? tapePlayer.setInput("Hover", value: isTapped)
            }
    }
}
