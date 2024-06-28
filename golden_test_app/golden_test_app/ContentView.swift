//
//  ContentView.swift
//  golden_test_app
//
//  Created by Jonathon Copeland on 5/15/24.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    var body: some View {
//        RiveViewRepresentable(viewModel: RiveViewModel(fileName: "dwarf"))
        GoldenTestViewRepresentable()
            .frame(width: 860, height: 540, alignment: .center)
    }
}
