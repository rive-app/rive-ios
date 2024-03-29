//
//  SwiftCannonGame.swift
//  RiveExample
//
//  Created by Zachary Duncan on 5/17/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftCannonGame: DismissableView {
    var dismiss: () -> Void = {}
    
    // MARK: RiveViewModel
    // This view model controls a file configured with:
    // - StateMachine
    // - Listeners
    @StateObject private var riveViewModel = RiveViewModel(fileName: "bullet_man_game")
    
    var body: some View {
        riveViewModel.view()
    }
}
