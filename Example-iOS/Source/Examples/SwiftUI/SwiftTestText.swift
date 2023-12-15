//
//  SwiftTestText.swift
//  Example (iOS)
//
//  Created by Zach Plata on 7/27/23.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct TextInputView: DismissableView {
    var dismiss: () -> Void = {}
    
    @State private var userInput: String = ""
    @StateObject private var rvm = RiveViewModel(fileName: "text_test_2")

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter text:")
                .font(.headline)
            TextField("Enter text...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: userInput, perform: { newValue in
                    if (!newValue.isEmpty) {
                        do {
                           try rvm.setTextRunValue("MyRun", textValue: userInput)
                        } catch {
                            debugPrint(error)
                        }
                    }
                })
            rvm.view()
        }
        .padding()
    }
}
