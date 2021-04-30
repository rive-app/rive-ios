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
    
    // This is needed to expose the view outside the framework
    public init(fromResource resource: String) {
        self.resource = resource
    }
    
    public func makeUIViewController(context: Context) -> RiveViewController {
        return RiveViewController(withResource: resource, withExtension: "riv")
    }

    public func updateUIViewController(_ uiViewController: RiveViewController, context: Context) {}
}
