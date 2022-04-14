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
    @IBOutlet weak var rviewSquareGoAround: RView!
    @IBOutlet weak var rviewSquareRollAround: RView!
    @IBOutlet weak var rviewCircle: RView!
    @IBOutlet weak var rviewStar: RView!
    
    var rSquareGoAround = RViewModel(
        fileName: "artboard_animations", artboardName: "Square", animationName: "goaround"
    )
    var rSquareRollAround = RViewModel(
        fileName: "artboard_animations", artboardName: "Square", animationName: "rollaround"
    )
    var rCircle = RViewModel(
        fileName: "artboard_animations", artboardName: "Circle"
    )
    var rStar = RViewModel(
        fileName: "artboard_animations", artboardName: "Star"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rSquareGoAround.setView(rviewSquareGoAround)
        rSquareRollAround.setView(rviewSquareRollAround)
        rCircle.setView(rviewCircle)
        rStar.setView(rviewStar)
    }
}
