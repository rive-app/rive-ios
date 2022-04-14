//
//  MultipleAnimations.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class MultipleAnimationsController: UIViewController {
    @IBOutlet weak var rviewSquareGoAround: RView!
    @IBOutlet weak var rviewSquareRollAround: RView!
    @IBOutlet weak var rviewCircle: RView!
    @IBOutlet weak var rviewStar: RView!
    var rSquareGoAround = RViewModel(RModel(fileName: "artboard_animations", artboardName: "Square", animationName: "goaround"))
    var rSquareRollAround = RViewModel(RModel(fileName: "artboard_animations", artboardName: "Square", animationName: "rollaround"))
    var rCircle = RViewModel(RModel(fileName: "artboard_animations", artboardName: "Circle"))
    var rStar = RViewModel(RModel(fileName: "artboard_animations", artboardName: "Star"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rSquareGoAround.configure(rview: rviewSquareGoAround)
        
        rSquareRollAround.configure(rview: rviewSquareRollAround)
        
        rCircle.configure(rview: rviewCircle)
        
        rStar.configure(rview: rviewStar)
    }
}
