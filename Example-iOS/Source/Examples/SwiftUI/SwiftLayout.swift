//
//  Layout.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime



struct SwiftLayout: DismissableView {
    var dismiss: () -> Void = {}
    
    @State private var fit: RiveFit = .contain
    @State private var alignment: RiveAlignment = .center
    @StateObject private var riveViewModel = RiveViewModel(fileName: "truck_v7", fit: .contain, alignment: .center)
    
    var body: some View {
        VStack {
            riveViewModel.view()
                .onChange(of: fit) { value in
                    riveViewModel.fit = value
                }
                .onChange(of: alignment) { value in
                    riveViewModel.alignment = value
                }
        }
        HStack {
            Text("Fit")
        }
        HStack {
            Button("Fill", action: {fit = .fill})
            Button("Contain", action: {fit = .contain})
            Button("Cover", action: {fit = .cover})
        }
        HStack {
            Button("Fit Width", action: {fit = .fitWidth})
            Button("Fit Height", action: {fit = .fitHeight})
            Button("Scale Down", action: {fit = .scaleDown})
        }
        HStack {
            Button("None", action: {fit = .noFit})
        }
        HStack {
            Text("Alignment")
        }
        HStack {
            Button("Top Left", action: {alignment = .topLeft})
            Button("Top Center", action: {alignment = .topCenter})
            Button("Top Right", action: {alignment = .topRight})
        }
        HStack {
            Button("Center Left", action: {alignment = .centerLeft})
            Button("Center", action: {alignment = .center})
            Button("Center Right", action: {alignment = .centerRight})
        }
        HStack {
            Button("Bottom Left", action: {alignment = .bottomLeft})
            Button("Bottom Center", action: {alignment = .bottomCenter})
            Button("Bottom Right", action: {alignment = .bottomRight})
        }
    }
}

