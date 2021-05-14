//
//  RiveSwitch.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/13/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI

struct RiveSwitch: View {
    @State var switchToOn: Bool = false
    @State var switchToOff: Bool = false
    @State var on: Bool = false
    
    let resource: String
    var onAnimation: String = "On"
    var offAnimation: String = "Off"
    var startAnimation: String = "StartOff"
    var action: ((Bool) -> Void)? = nil
    
    var body: some View {
        RiveSwitchBridge(resource: resource, fit: .cover, switchToOn: $switchToOn, switchToOff: $switchToOff)
            .frame(width: 100, height: 50)
            .onTapGesture {
                switchToOn = false
                switchToOff = false
                if on {
                    switchToOff = true
                } else {
                    switchToOn = true
                }
                on = !on
                action?(on)
            }
    }
}

struct RiveSwitch_Previews: PreviewProvider {
    static var previews: some View {
        RiveSwitch(resource: "switch")
    }
}
