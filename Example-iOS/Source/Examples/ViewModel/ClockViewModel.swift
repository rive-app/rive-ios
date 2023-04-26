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
    private var hour: Int = 0
    private var minute: Int = 0
    private var second: Int = 0

    @Published var time: Double = 0 {
        didSet {
            setInput("isTime", value: time > 12 ? time-12 : time)
        }
    }
    
    @Published var followTimer: Bool = false {
        didSet {
            if followTimer {
                timer = Timer.scheduledTimer(
                    withTimeInterval: 1.0,
                    repeats: true,
                    block: { [weak self] timer in
                        guard let self else {
                            timer.invalidate();
                            return
                        }

                        let date = Date()
                        let calendar = Calendar.current

                        self.hour = calendar.component(.hour, from: date)
                        self.minute = calendar.component(.minute, from: date)
                        self.second = calendar.component(.second, from: date)

                        self.time = Double(self.hour) + Double(self.minute)/60 + Double(self.second)/1200
                    }
                )
            } else {
                timer?.invalidate()
            }
        }
    }
    
    convenience init() {
        self.init(fileName: "watch_v1", stateMachineName: "Time")
        followTimer = true
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override func view() -> AnyView {
        AnyView(
            ZStack {
                Color.gray
                
                VStack {
                    super.view()
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
                    
                    let normalizedHour = hour%12 == 0 ? 12 : hour%12
                    Text("Time: \(normalizedHour):\(minute):\(second)")
                        .foregroundColor(.white)
                        .padding(.bottom)
                    
                    Slider(value: Binding(
                        get: { self.time },
                        set: { self.time = round($0 * 100) / 100 }
                    ), in: 0...24, step: 0.01)
                    .padding()
                    .disabled(followTimer)
                }
            }
        )
    }
}
