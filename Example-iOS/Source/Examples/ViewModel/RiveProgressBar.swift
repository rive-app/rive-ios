//
//  RiveProgressBar.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RiveProgressBar: RiveViewModel {
    var progress: Double {
        didSet {
            try? setInput("Energy", value: progress)
        }
    }
    
    init(_ initialProgress: Double = 0) {
        progress = initialProgress
        super.init(fileName: "energy_bar_example", stateMachineName: "State Machine ", fit: .fitCover)
    }
    
    func formattedView() -> some View {
        super.view()
            .aspectRatio(4, contentMode: .fill)
    }
}
