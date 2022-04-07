//
//  SimpleSlider.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/6/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI

class SimpleSliderViewController: UIViewController {
    @IBOutlet weak var rview: RView!
    @IBOutlet weak var uislider: UISlider!
    
    var rslider = RViewModel.riveslider
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rview = rslider.createRView()
        print(rslider.rview?.artboard?.name() ?? "Ain't found no Artboard")
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        try? rslider.setInput("FillPercent", value: uislider.value)
        print(rslider.rview?.artboard?.name() ?? "Ain't found no Artboard")
    }
}
