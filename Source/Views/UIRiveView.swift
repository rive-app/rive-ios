//
//  UIRiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/29/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI

public struct UIRiveView: UIViewControllerRepresentable {
    let resource: String
    let fit: Fit
    let alignment: RiveRuntime.Alignment
    
    
    // This is needed to expose the view outside the framework
    public init(
        fromResource resource: String,
        fromFit fit: Fit = Fit.Contain,
        fromAlignment alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    ) {
        self.resource = resource
        self.fit = fit
        self.alignment = alignment
    }
    
    public func makeUIViewController(context: Context) -> RiveViewController {
        return RiveViewController(withResource: resource, withFit: fit, withAlignment: alignment)
    }

    public func updateUIViewController(_ uiViewController: RiveViewController, context: Context) {}
}
