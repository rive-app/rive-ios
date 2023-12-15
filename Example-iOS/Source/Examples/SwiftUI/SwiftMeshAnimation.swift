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
    var dismiss: () -> Void = {}
    
    // MARK: RiveViewModel
    // This view model specifies the exact StateMachine that it wants from the file
    @State var isTapped: Bool = false
    @StateObject private var tapePlayer = RiveViewModel(fileName: "prop_example", stateMachineName: "State Machine 1")
    
    var body: some View {
        tapePlayer.view()
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture {
                isTapped = !isTapped
                tapePlayer.setInput("Hover", value: isTapped)
            }
    }
}
