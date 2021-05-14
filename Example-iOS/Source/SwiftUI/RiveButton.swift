//
//  RiveButton.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/13/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI

struct RiveButton: View {
    @State var play: Bool = false
    
    let resource: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        RiveButtonBridge(resource: resource, fit: .cover, play: $play)
            .frame(width: 100, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .onTapGesture {
                print("Rive button click")
                play = true
                action?()
            }
    }
}

struct RiveButton_Previews: PreviewProvider {
    static var previews: some View {
        RiveButton(resource: "pull") {}
    }
}
