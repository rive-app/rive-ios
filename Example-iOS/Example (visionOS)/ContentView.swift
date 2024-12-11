//
//  ContentView.swift
//  Example (visionOS)
//
//  Created by David Skuza on 10/25/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    @StateObject var viewModel = RiveViewModel(fileName: "streaming", fit: .fill)

    var body: some View {
        viewModel.view()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
