//
//  SwiftAudioAssets.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 11/04/2024.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation

import SwiftUI
import RiveRuntime

struct SwiftAudioAssets: DismissableView {
    var dismiss: () -> Void = {}
    @StateObject private var riveViewModel = RiveViewModel(
        fileName: "lip-sync_test",
        stateMachineName: "State Machine 1",
        artboardName: "Lip_sync_2"
    );
    
    var body: some View {
        riveViewModel
            .view()
            .onAppear {
                riveViewModel.riveModel?.volume = 0.01
            }
    }
}
