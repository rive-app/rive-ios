//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

/// This shows how to utilize one animation file to show content in different artboards and
/// different animations within those artboards
class MultipleAnimationsController: UIViewController {
    @IBOutlet weak var rviewSquareGoAround: RiveView!
    @IBOutlet weak var rviewSquareRollAround: RiveView!
    @IBOutlet weak var rviewCircle: RiveView!
    @IBOutlet weak var rviewStar: RiveView!
    
    var rSquareGoAround = RiveViewModel(
        fileName: "artboard_animations", artboardName: "Square", animationName: "goaround"
    )
    var rSquareRollAround = RiveViewModel(
        fileName: "artboard_animations", artboardName: "Square", animationName: "rollaround"
    )
    var rCircle = RiveViewModel(
        fileName: "artboard_animations", artboardName: "Circle"
    )
    var rStar = RiveViewModel(
        fileName: "artboard_animations", artboardName: "Star"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rSquareGoAround.configureView(rviewSquareGoAround)
        rSquareRollAround.configureView(rviewSquareRollAround)
        rCircle.configureView(rviewCircle)
        rStar.configureView(rviewStar)
    }
}
