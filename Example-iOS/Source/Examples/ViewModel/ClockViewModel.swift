//
//  TouchEvents.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/26/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class ClockViewModel: NewRiveViewModel {
    var timer: Timer!
    var hours: Double = 0 {
        didSet {
            try? setInput("isTime", value: hours > 12 ? hours-12 : hours)
        }
    }
    
    convenience init() {
        self.init(fileName: "watch_v1", stateMachineName: "Time")
        print("Clock widget init'd")
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let date = Date()
            let calendar = Calendar.current

            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let second = calendar.component(.second, from: date)
            
            self.hours = Double(hour) + Double(minute)/60 + Double(second)/1200
        }
    }
    
    deinit {
        timer.invalidate()
    }
}
