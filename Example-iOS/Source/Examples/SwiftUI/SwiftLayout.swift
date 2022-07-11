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
    
    @State private var fit = Fit.fitContain
    @State private var alignment = Alignment.alignmentCenter
    
    var body: some View {
        VStack {
            RiveViewModel(fileName: "truck_v7", fit: fit, alignment: alignment).view()
        }
        HStack {
            Text("Fit")
        }
        HStack {
            Button("Fill", action: {fit = .fitFill})
            Button("Contain", action: {fit = .fitContain})
            Button("Cover", action: {fit = .fitCover})
        }
        HStack {
            Button("Fit Width", action: {fit = .fitFitWidth})
            Button("Fit Height", action: {fit = .fitFitHeight})
            Button("Scale Down", action: {fit = .fitScaleDown})
        }
        HStack {
            Button("None", action: {fit = .fitNone})
        }
        HStack {
            Text("Alignment")
        }
        HStack {
            Button("Top Left", action: {alignment = .alignmentTopLeft})
            Button("Top Center", action: {alignment = .alignmentTopCenter})
            Button("Top Right", action: {alignment = .alignmentTopRight})
        }
        HStack {
            Button("Center Left", action: {alignment = .alignmentCenterLeft})
            Button("Center", action: {alignment = .alignmentCenter})
            Button("Center Right", action: {alignment = .alignmentCenterRight})
        }
        HStack {
            Button("Bottom Left", action: {alignment = .alignmentBottomLeft})
            Button("Bottom Center", action: {alignment = .alignmentBottomCenter})
            Button("Bottom Right", action: {alignment = .alignmentBottomRight})
        }
    }
}

