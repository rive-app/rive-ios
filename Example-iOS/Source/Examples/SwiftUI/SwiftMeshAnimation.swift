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

    // TODO: 
    // Review viewmodel set-up here to avoid recreation & also loading files on launch.
    @State var isTapped: Bool = false
    
    var body: some View {
        let tapePlayer = RiveViewModel(fileName: "prop_example", stateMachineName: "State Machine 1")
        tapePlayer.view()
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture {
                isTapped = !isTapped
                tapePlayer.setInput("Hover", value: isTapped)
            }
    }
}
