//
//  SimpleSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/6/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import RiveRuntime
import SwiftUI

class SimpleSliderViewController: UIViewController {
    @IBOutlet weak var riveView: NewRiveView!
    var rslider: NewRiveViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rslider = RiveSlider()
        rslider.configureView(riveView)
    }
}
