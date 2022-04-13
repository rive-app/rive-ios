//
//  RSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RSlider: RViewModel {
    var progress: Double {
        didSet {
            try? setInput("FillPercent", value: progress)
        }
    }
    
    init(_ initialProgress: Double = 0) {
        let model = RModel(fileName: "riveslider7", stateMachineName: "Slide", fit: .fitCover)
        progress = initialProgress
        super.init(model)
    }
    
    func formattedView() -> some View {
        return super.view()
            .aspectRatio(2.5, contentMode: .fill)
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        touchMoved(onArtboard: artboard, atLocation: location)
    }
    
    func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        progress = Double(location.x / rview!.frame.width) * 100
    }
}
