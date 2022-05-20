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
    @StateObject var clock = ClockViewModel()
    @StateObject var jelly = RiveViewModel(fileName: "hero_editor", stateMachineName: "Jellyfish")
    @StateObject var playButton = RiveViewModel(fileName: "play_button_event_example", stateMachineName: "State Machine")
    @StateObject var lighthouse = RiveViewModel(fileName: "switch_event_example", stateMachineName: "Main State Machine")
    @StateObject var eightball = RiveViewModel(fileName: "magic_8-ball_v2", stateMachineName: "Main State Machine")
    @StateObject var bearGuy = RiveViewModel(fileName: "leg_day_events_example", stateMachineName: "Don't Skip Leg Day")
    @StateObject var toggle = RiveViewModel(fileName: "light_switch", stateMachineName: "Switch")
    
    var body: some View {
        ScrollView {
            VStack {
                jelly.view()
                    .aspectRatio(1, contentMode: .fit)
                
                playButton.view()
                    .aspectRatio(1, contentMode: .fit)

                lighthouse.view()
                    .aspectRatio(1, contentMode: .fit)

                eightball.view()
                    .aspectRatio(1, contentMode: .fit)

                bearGuy.view()
                    .aspectRatio(1, contentMode: .fit)

                clock.controlsView()

                toggle.view()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
