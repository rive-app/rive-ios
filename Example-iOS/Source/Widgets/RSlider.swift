//
//  RSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime

class RSlider: RViewModel {
    init() {
        let model = RModel(fileName: "riveslider7", stateMachineName: "Slide")
        super.init(model)
    }
    
    override func setView(_ rview: RView) {
        super.setView(rview)
        rview.touchDelegate = self
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        touchMoved(onArtboard: artboard, atLocation: location)
    }
    
    func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        let percent = Float(location.x / rview!.frame.width) * 100
        try? setInput("FillPercent", value: percent)
    }
}
