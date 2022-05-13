//
//  RiveSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RiveSlider: NewRiveViewModel {
    var progress: Double {
        didSet {
            try? setInput("FillPercent", value: progress)
        }
    }
    
    init(_ initialProgress: Double = 0) {
        let model = try! NewRiveModel(riveFile: RiveFile(name: "riveslider"), stateMachineName: "Slide")
        progress = initialProgress
        
        super.init(model, fit: .fitScaleDown)
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        touchMoved(onArtboard: artboard, atLocation: location)
    }
    
    func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        progress = Double(location.x / riveView!.frame.width) * 100
    }
}
