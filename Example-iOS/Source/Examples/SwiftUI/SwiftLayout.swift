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
    // Set this to a different value to have the artboard scale when using autoResizeArtboard
    @State private var scaleFactor: Double = RiveViewModel.layoutScaleFactorAutomatic
    @StateObject private var riveViewModel = RiveViewModel(fileName: "layout_test", fit: .contain)
    @State var collapsed = false;

    var body: some View {
        VStack {
            riveViewModel.view()
                .onChange(of: fit) { value in
                    riveViewModel.fit = value
                }
                .onChange(of: alignment) { value in
                    riveViewModel.alignment = value
                }
                .onChange(of: scaleFactor) { value in
                    riveViewModel.layoutScaleFactor = value
                }
        }.frame(width: self.collapsed ? 150 : 400, height: self.collapsed ? 300 : 400)
        .animation(.default, value: collapsed)
        HStack {
            Button("Toggle Size", action: {collapsed.toggle()})
        }
        
        Spacer()
        
        Group {
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
                Button("Resize Artboard", action: {fit = .layout})
                Button("None", action: {fit = .noFit})
            }
        }

        if fit == .layout {
            Group {
                Stepper {
                    Text("Scale factor: \(scaleFactor == RiveViewModel.layoutScaleFactorAutomatic ? "Automatic" : "\(Int(scaleFactor))")")
                } onIncrement: {
                    if scaleFactor == RiveViewModel.layoutScaleFactorAutomatic {
                        scaleFactor = 1
                    } else {
                        scaleFactor += 1
                    }
                } onDecrement: {
                    guard scaleFactor > RiveViewModel.layoutScaleFactorAutomatic else { return }

                    scaleFactor -= 1
                    if scaleFactor == 0 {
                        scaleFactor = RiveViewModel.layoutScaleFactorAutomatic
                    }
                }
            }.padding()
        }

        Spacer()
        
        Group {
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
}

