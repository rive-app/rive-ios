//
//  RiveSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RiveSlider: RiveViewModel {
    var progress: Double {
        didSet {
            setInput("FillPercent", value: progress)
        }
    }
    
    init(_ initialProgress: Double = 0) {
        progress = initialProgress
        super.init(fileName: "riveslider", stateMachineName: "Slide", fit: .fitScaleDown)
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        touchMoved(onArtboard: artboard, atLocation: location)
    }
    
    func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        progress = Double(location.x / riveView!.frame.width) * 100
    }
}
