//
//  RSwitch.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class RSwitch: RViewModel {
    var isOn = false {
        didSet {
            stop()
            try? play(animationName: isOn ? onAnimation : offAnimation)
            action?(isOn)
        }
    }
    
    private let onAnimation: String = "On"
    private let offAnimation: String = "Off"
    private let startAnimation: String = "StartOff"
    
    var action: ((Bool) -> Void)? = nil
    
    convenience init() {
        self.init(fileName: "switch")
        fit = .fitCover
        animationName = startAnimation
    }
    
    func view(_ action: ((Bool) -> Void)? = nil) -> some View {
        self.action = action
        return super.view().frame(width: 100, height: 50, alignment: .center)
    }
    
    func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        isOn.toggle()
    }
}
