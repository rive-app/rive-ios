//
//  SwiftMultipleArtboard.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/22/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

@available(iOS 15.0, *)
struct SwiftMultipleArtboards: DismissableView {
    var dismiss: () -> Void = {}
    
    var viewModels = [
        IconViewModel(item: "CHAT"),
        IconViewModel(item: "SEARCH"),
        IconViewModel(item: "TIMER")
    ]
    
    var body: some View {
        HStack {
            ForEach(viewModels) { $0.view() }
        }
        .background(.black)
    }
}

class IconViewModel: RiveViewModel, Identifiable {
    private let icons = ["CHAT", "SEARCH", "TIMER"]
    private var isActive = false {
        didSet {
            if isActive {
                try? setInput("active", value: true)
            } else {
                pause()
            }
        }
    }
    
    convenience init(item: String) {
        self.init(fileName: "animated_icon_set_-_1_color", stateMachineName: "\(item)_Interactivity", artboardName: item)
    }
    
    func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        // If you want to change the model mid-flight
//        let icon = "CHAT"
//        stateMachineName = "\(icon)_Interactivity"
//        self.artboardName = icon
//        refreshView()
        
        isActive.toggle()
    }
}

@available(iOS 15.0, *)
struct LoopView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftMultipleArtboards()
    }
}
