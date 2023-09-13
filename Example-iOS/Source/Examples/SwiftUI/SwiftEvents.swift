//
//  SwiftEvents.swift
//  RiveExample
//
//  Created by Zach Plata on 8/28/23.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftEvents: DismissableView {
    var dismiss: () -> Void = {}
    @StateObject private var rvm = RiveEventsVMExample()

    var body: some View {
        VStack {
            rvm.view()
            Text("Event Message")
                .font(.headline)
                .padding(.bottom, 10)
            Text(rvm.eventText)
                .padding()
                .background(rvm.eventText.isEmpty ? Color.clear : Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

class RiveEventsVMExample: RiveViewModel {
    @Published var eventText = ""

    init() {
        super.init(fileName: "rating_animation")
    }

    func view() -> some View {
        return super.view().frame(width: 400, height: 400, alignment: .center)
    }

    @objc func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        debugPrint("Event Name: \(riveEvent.name())")
        debugPrint("Event Type: \(riveEvent.type())")
        if let openUrlEvent = riveEvent as? RiveOpenUrlEvent {
            debugPrint("Open URL Event Properties: \(openUrlEvent.properties())")
            if let url = URL(string: openUrlEvent.url()) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #else
                NSWorkspace.shared.open(url)
                #endif
            }
        } else if let generalEvent = riveEvent as? RiveGeneralEvent {
            let genEventProperties = generalEvent.properties();
            debugPrint("General Event Properites: \(genEventProperties)")
            if let msg = genEventProperties["message"] {
                eventText = msg as! String
            }
        }

    }
}
