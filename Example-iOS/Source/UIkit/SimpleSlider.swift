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
    @IBOutlet weak var rview: RView!
    @IBOutlet weak var uislider: UISlider!
    
    var rslider: RViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rslider = newSliderVM()
        rslider.configure(view: rview)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        try? rslider.setInput("FillPercent", value: uislider.value * 100)
    }
    
    private func newSliderVM() -> RViewModel {
        let model = RModel(fileName: "riveslider7", stateMachineName: "Slide")
        return RViewModel(model)
    }
}
