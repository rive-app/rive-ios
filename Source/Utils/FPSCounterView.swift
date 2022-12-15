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
    private let updateInterval: Double = 0.5
    private var timeSinceUpdate: Double = 0
    
    internal convenience init() {
        self.init(frame: CGRect(x: 1, y: 1, width: 70, height: 20))
        backgroundColor = .darkGray
        textColor = .white
        textAlignment = .center
        font = UIFont.systemFont(ofSize: 11, weight: .regular)
        alpha = 0.75
        clipsToBounds = true
        layer.cornerRadius = 5
        text = "..."
        
        fpsFormatter.minimumFractionDigits = 2
        fpsFormatter.maximumFractionDigits = 2
        fpsFormatter.roundingMode = .down
    }
    
    internal func elapsed(time elapsedTime: Double) {
        if elapsedTime != 0 {
            timeSinceUpdate += elapsedTime
            
            if timeSinceUpdate >= updateInterval {
                timeSinceUpdate = 0
                text = fpsFormatter.string(from: NSNumber(value: 1 / elapsedTime))! + "fps"
            }
        }
    }
    
    internal func stopped() {
        text = "Stopped"
    }
}
