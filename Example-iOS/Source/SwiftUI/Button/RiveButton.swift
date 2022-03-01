//
//  RiveButton.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/13/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct RiveButton: View {
    public init(
        resource: String,
        action: (() -> Void)?
    ) {
        self.view = try?
        RiveView(resource: resource, fit: .fitCover, autoplay: false)
        self.action = action
        
    }
    var view: RiveView?
    var action: (() -> Void)? = nil
    
    var body: some View {
        RiveViewSwift(
            riveView: view!
        )
            .frame(width: 100, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .onTapGesture {
                self.view!.stop()
                try? self.view!.play()
                
                action?()
            }
    }
}

struct RiveButton_Previews: PreviewProvider {
    static var previews: some View {
        RiveButton(resource: "pull"){}
    }
}
