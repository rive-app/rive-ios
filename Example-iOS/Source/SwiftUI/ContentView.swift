//
//  ContentView.swift
//  RiveExample
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    var body: some View {
        UIRiveView(
            fromResource: "juice_v7",
            fromFit: Fit.Cover,
            fromAlignment: Alignment.Center,
            fromArtboardName: "New Artboard"
        )
    }
}
