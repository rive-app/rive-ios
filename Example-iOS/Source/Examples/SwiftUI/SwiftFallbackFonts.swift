//
//  SwiftFallbackFonts.swift
//  RiveExample
//
//  Created by David Skuza on 9/3/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftFallbackFonts: View, DismissableView {
    var dismiss: () -> Void = {}

    @StateObject private var viewModel = RiveViewModel(fileName: "fallback_fonts")

    private var runBinding: Binding<String> {
        Binding {
            return self.viewModel.getTextRunValue("text") ?? ""
        }
        set: { text in
            try? self.viewModel.setTextRunValue("text", textValue: text)
            self.viewModel.play()
        }
    }

    var body: some View {
        VStack() {
            viewModel.view().scaledToFit()

            Text(
                "The included Rive font only contains characters in the set A...G. Fallback font(s) will be used to draw missing characters."
            )
            .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            .font(.caption)
            .padding()

            TextField("Add text with missing characters", text: runBinding)
                .textFieldStyle(.roundedBorder)
                .padding()

            Spacer().frame(maxHeight: .infinity)
        }
        .onAppear {
            RiveFont.fallbackFonts = [
                // You can use a font descriptor that will generate a system font
                RiveFallbackFontDescriptor(design: .default, weight: .regular, width: .standard),
                // ...or an explicit system font
                UIFont.systemFont(ofSize: 12, weight: .heavy),
                // ...or a UIFont by name, or any way of initializing a UIFont
                UIFont(name: "Times New Roman", size: 12)!
            ]
        }
    }
}
