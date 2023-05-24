//
//  ContentView.swift
//  Example (macOS)
//
//  Created by Maxwell Talbot on 17/05/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    var body: some View {
        VStack {
            RiveViewModel(fileName: "magic_8-ball_v2").view()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
