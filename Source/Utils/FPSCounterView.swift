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
    private let updateInterval: Double = 1.0
    private var timestampOnLastUpdate: CFTimeInterval = 0
    private var framesDrawnSinceLastUpdate: Int = 0
    
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
    
    internal func didDrawFrame(timestamp: CFTimeInterval) {
        if (timestampOnLastUpdate == 0) {
            timestampOnLastUpdate = timestamp
            framesDrawnSinceLastUpdate = 0
            return
        }

        framesDrawnSinceLastUpdate += 1

        let elapsedSinceLastUpdate = timestamp - timestampOnLastUpdate
        if elapsedSinceLastUpdate >= updateInterval {
            text = fpsFormatter.string(from: NSNumber(value: Double(framesDrawnSinceLastUpdate) / elapsedSinceLastUpdate))! + "fps"
            timestampOnLastUpdate = timestamp
            framesDrawnSinceLastUpdate = 0
        }
    }
    
    internal func stopped() {
        text = "Stopped"
    }
}
