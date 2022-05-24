//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//


import SwiftUI
import RiveRuntime

struct SwiftSimpleAnimation: DismissableView {
    var dismiss: () -> Void = {}
    var viewModel = RiveViewModel(fileName: "button", autoPlay: false)
    
    var body: some View {
        ZStack {
            Color.gray
                
            VStack {
                viewModel.view()
                
                HStack {
                    PlayerButton(title: "play") {
                        viewModel.play(animationName: "active")
                    }
                    
                    PlayerButton(title: "pause") {
                        viewModel.pause()
                    }
                    
                    PlayerButton(title: "stop") {
                        viewModel.stop()
                    }
                    
                    PlayerButton(title: "backward.end") {
                        viewModel.reset()
                    }
                }
            }
            .padding()
        }
        .ignoresSafeArea()
    }
    
    struct PlayerButton: View {
        var title: String
        var action: ()->Void
        
        var body: some View {
            Button {
                action()
                
            } label: {
                ZStack {
                    Color.blue
                    Image(systemName: title + ".fill")
                        .foregroundColor(.white)
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .padding()
            }
        }
    }
}
