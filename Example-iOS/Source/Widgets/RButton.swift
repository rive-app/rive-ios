//
//  RButton.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RButton: RViewModel {
    private let input = "IsPressed"
    var action: (() -> Void)? = nil
    
    init(fileName: String = "rbutton") {
        let model = RModel(fileName: fileName, stateMachineName: "State Machine 1", fit: .fitCover, autoplay: false)
        super.init(model)
    }
    
    func view(_ action: (() -> Void)?) -> some View {
        self.action = action
        return super.view()
            .frame(width: 100, height: 30)
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        stop()
        try? setInput(input, value: true)
    }
    
    func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        stop()
        action?()
        touchCancelled(onArtboard: artboard, atLocation: location)
    }
    
    func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        try? setInput(input, value: false)
    }
}
