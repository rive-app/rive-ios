//
//  RiveViewSwift.swift
//  RiveRuntime
//
//  Created by Zach Plata on 2/27/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct RiveViewSwift: UIViewRepresentable {
    let riveView: RiveView
    public init(
        riveView: RiveView
    ) {
        self.riveView = riveView
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RiveView {
        return riveView
    }
    
    public func updateUIView(
        _ riveView: RiveView,
        context: UIViewRepresentableContext<RiveViewSwift>
    ) {
        print("RiveViewSwift - updateUIView")
        print(riveView)
    }
    
    public static func dismantleUIView(
        _ riveView: RiveView,
        coordinator: Self.Coordinator
    ) {
        riveView.stop()
    }
    
}
