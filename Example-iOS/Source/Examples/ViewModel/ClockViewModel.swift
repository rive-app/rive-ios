//
//  TouchEvents.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/26/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class ClockViewModel: RiveViewModel {
    private var timer: Timer!
    
    @Published var hours: Double = 0 {
        didSet {
            try? setInput("isTime", value: hours > 12 ? hours-12 : hours)
        }
    }
    
    @Published var followTimer: Bool = false {
        didSet {
            if followTimer {
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    let date = Date()
                    let calendar = Calendar.current

                    let hour = calendar.component(.hour, from: date)
                    let minute = calendar.component(.minute, from: date)
                    let second = calendar.component(.second, from: date)
                    
                    self.hours = Double(hour) + Double(minute)/60 + Double(second)/1200
                }
            } else {
                timer?.invalidate()
            }
        }
    }
    
    convenience init() {
        self.init(fileName: "watch_v1", stateMachineName: "Time")
        print("Clock widget init'd")
        
        followTimer = true
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func controlsView() -> some View {
        return ZStack {
            Color.gray
            
            VStack {
                view()
                    .aspectRatio(1, contentMode: .fit)
                
                Button {
                    self.followTimer.toggle()
                } label: {
                    ZStack {
                        Color.blue
                        Text(self.followTimer ? "Real Time" : "Manual")
                            .bold()
                    }
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 75, alignment: .center)
                .cornerRadius(10)
                .padding()
                
                Text("Hour: \(round(hours * 100) / 100)")
                    .foregroundColor(.white)
                    .padding(.bottom)
                
                Slider(value: Binding(
                    get: { self.hours },
                    set: { self.hours = round($0 * 100) / 100 }
                ), in: 0...24, step: 0.01)
                .padding()
                .disabled(followTimer)
            }
        }
    }
}
