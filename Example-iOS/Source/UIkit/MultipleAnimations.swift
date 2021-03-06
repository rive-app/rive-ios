//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class MultipleAnimations: UIView {
    @IBOutlet var squareGoAround: RiveView!
    @IBOutlet var squareRollAround: RiveView!
    @IBOutlet var circle: RiveView!
    @IBOutlet var star: RiveView!
}

class MultipleAnimationsController: UIViewController {
    
    let loopResourceName = "artboard_animations"
    
    override public func loadView()  {
        super.loadView()
        
        guard let multipleAnimationView = view as? MultipleAnimations else {
            fatalError("Could not find LayoutView")
        }
        try? multipleAnimationView.squareGoAround.configure(
            getRiveFile(resourceName: loopResourceName),
            andArtboard: "Square",
            andAnimation: "goaround"
        )
        try? multipleAnimationView.squareRollAround.configure(
            getRiveFile(resourceName: loopResourceName),
            andArtboard: "Square",
            andAnimation: "rollaround"
        )
        try? multipleAnimationView.circle.configure(
            getRiveFile(resourceName: loopResourceName),
            andArtboard: "Circle"
        )
        try? multipleAnimationView.star?.configure(
            getRiveFile(resourceName: loopResourceName),
            andArtboard: "Star"
        )
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
}
