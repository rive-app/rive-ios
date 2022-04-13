//
//  RProgressBar.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RProgressBar: RViewModel {
    var progress: Double {
        didSet {
            try? setInput("Energy", value: progress)
        }
    }
    
    init(_ initialProgress: Double = 0) {
        let model = RModel(fileName: "energy_bar_example", stateMachineName: "State Machine ", fit: .fitCover)
        progress = initialProgress
        super.init(model)
    }
    
    func formattedView() -> some View {
        super.view()
            .aspectRatio(4, contentMode: .fill)
    }
}
