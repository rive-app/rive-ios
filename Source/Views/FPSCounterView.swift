//
//  FPSCounterView.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 5/11/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import UIKit

class FPSCounterView: UILabel {
    private let fpsFormatter = NumberFormatter()
    
    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 75, height: 30))
        backgroundColor = .darkGray
        textColor = .white
        textAlignment = .center
        alpha = 0.75
        clipsToBounds = true
        layer.cornerRadius = 10
        text = "..."
        
        fpsFormatter.minimumFractionDigits = 2
        fpsFormatter.maximumFractionDigits = 2
        fpsFormatter.roundingMode = .down
    }
    
    internal func elapsed(time elapsedTime: Double) {
        if elapsedTime != 0 {
            text = fpsFormatter.string(from: NSNumber(value: 1 / elapsedTime))! + "fps"
        }
    }
    
    internal func stopped() {
        text = "Stopped"
    }
}
