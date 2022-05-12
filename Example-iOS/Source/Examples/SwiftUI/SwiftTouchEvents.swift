//
//  SwiftTouchEvents.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/26/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftTouchEvents: DismissableView {
    var dismiss: () -> Void = {}
    
    var body: some View {
        ScrollView {
            VStack {
                RiveViewModel(fileName: "hero_editor", stateMachineName: "Jellyfish")
                    .view()
                    .aspectRatio(1, contentMode: .fit)
                
                RiveViewModel(fileName: "play_button_event_example", stateMachineName: "State Machine")
                    .view()
                    .aspectRatio(1, contentMode: .fit)

                RiveViewModel(fileName: "switch_event_example", stateMachineName: "Main State Machine")
                    .view()
                    .aspectRatio(1, contentMode: .fit)

                RiveViewModel(fileName: "magic_8-ball_v2", stateMachineName: "Main State Machine")
                    .view()
                    .aspectRatio(1, contentMode: .fit)

                RiveViewModel(fileName: "leg_day_events_example", stateMachineName: "Don't Skip Leg Day")
                    .view()
                    .aspectRatio(1, contentMode: .fit)

                ClockViewModel()
                    .view()
                    .aspectRatio(1, contentMode: .fit)

                RiveViewModel(fileName: "light_switch", stateMachineName: "Switch")
                    .view()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
