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
    var viewModel = RiveViewModel(fileName: "truck", autoPlay: false)
    
    var body: some View {
        viewModel.view()
        
        HStack {
            PlayerButton(title: "▶︎") {
                viewModel.play()
            }
            
            PlayerButton(title: " ▍▍") {
                viewModel.pause()
            }
            
            PlayerButton(title: "◼︎") {
                viewModel.stop()
            }
        }
        .padding()
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
                    Text(title)
                        .foregroundColor(.white)
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .padding()
            }
        }
    }
}
