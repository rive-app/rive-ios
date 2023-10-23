//
//  SwiftVariableFPS.swift
//  Example (iOS)
//
//  Created by Zach Plata on 10/20/23.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftVariableFPS: DismissableView {
    var dismiss: () -> Void = {}
    
    private var stateChanger = RiveViewModel(fileName: "skills", stateMachineName: "Designer's Test")
    
    var body: some View {
        ScrollView{
            VStack {
                stateChanger.view()
                    .frame(height:200)
                
                HStack{
                    Button("Prefer 30 fps") {
                        if #available(iOS 15.0, *) {
                            stateChanger.setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange(minimum: 30, maximum: 120, preferred: 30))
                        } else {
                            stateChanger.setPreferredFramesPerSecond(preferredFramesPerSecond: 30)
                        }
                    }
                    Button("Prefer 60 fps") {
                        if #available(iOS 15.0, *) {
                            stateChanger.setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60))
                        } else {
                            stateChanger.setPreferredFramesPerSecond(preferredFramesPerSecond: 60)
                        }
                    }
                    Button("Prefer 120 fps") {
                        if #available(iOS 15.0, *) {
                            stateChanger.setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120))
                        } else {
                            stateChanger.setPreferredFramesPerSecond(preferredFramesPerSecond: 120)
                        }
                    }
                }
                
            }
        }.onAppear() {
            if #available(iOS 15.0, *) {
                stateChanger.setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120))
            } else {
                stateChanger.setPreferredFramesPerSecond(preferredFramesPerSecond: 120)
            }
        }
    }
}


