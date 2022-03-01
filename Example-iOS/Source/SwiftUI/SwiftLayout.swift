//
//  Layout.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 01/03/2022.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftLayout: View {
    var view = try!RiveView(resource: "off_road_car_blog")
    var body: some View {
        VStack {
            RiveViewSwift(riveView:view)
        }
        HStack {
            Text("Fit")
        }
        HStack {
            Button("Fill", action: {view.fit = .fitFill})
            Button("Contain", action: {view.fit = .fitContain})
            Button("Cover", action: {view.fit = .fitCover})
        }
        HStack {
            Button("Fit Width", action: {view.fit = .fitFitWidth})
            Button("Fit Height", action: {view.fit = .fitFitHeight})
            Button("Scale Down", action: {view.fit = .fitScaleDown})
        }
        HStack {
            Button("None", action: {view.fit = .fitNone})
        }
        HStack {
            Text("Alignment")
        }
        HStack {
            Button("Top Left", action: {view.alignment = .alignmentTopLeft})
            Button("Top Center", action: {view.alignment = .alignmentTopCenter})
            Button("Top Right", action: {view.alignment = .alignmentTopRight})
        }
        HStack {
            Button("Center Left", action: {view.alignment = .alignmentCenterLeft})
            Button("Center", action: {view.alignment = .alignmentCenter})
            Button("Center Right", action: {view.alignment = .alignmentCenterRight})
        }
        HStack {
            Button("Bottom Left", action: {view.alignment = .alignmentBottomLeft})
            Button("Bottom Center", action: {view.alignment = .alignmentBottomCenter})
            Button("Bottom Right", action: {view.alignment = .alignmentBottomRight})
        }
    }
}

