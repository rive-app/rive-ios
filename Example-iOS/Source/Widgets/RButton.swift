//
//  RButton.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class RButton: RViewModel {
    var action: (() -> Void)? = nil
    
    init(fileName: String) {
        let model = RModel(fileName: fileName, fit: .fitCover, autoplay: false)
        super.init(model)
    }
    
    func view(_ action: (() -> Void)?) -> some View {
        self.action = action
        return super.view()
            .frame(width: 100, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
    
    func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        stop()
        try? play(animationName: "Pull")
        action?()
    }
}
