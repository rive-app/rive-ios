//
//  RiveSwitch.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/13/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct RiveSwitch: View {
    @State var switchToOn: Bool = false
    @State var switchToOff: Bool = false
    @State var on: Bool = false
    
    let resource: String
    let controller: RiveController = RiveController()
    var onAnimation: String = "On"
    var offAnimation: String = "Off"
    var startAnimation: String = "StartOff"
    var action: ((Bool) -> Void)? = nil
    
    var body: some View {
        RiveViewSwift(resource: resource, fit: .constant(.fitCover), animation: startAnimation, controller: controller)
            .frame(width: 100, height: 50)
            .onTapGesture {
                on = !on
                self.controller.stop()
                try? self.controller.play(on ? onAnimation : offAnimation)
                action?(on)
            }
    }
}

struct RiveSwitch_Previews: PreviewProvider {
    static var previews: some View {
        RiveSwitch(resource: "switch")
    }
}
