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
        rslider = RSlider()
        rslider.configure(rview: rview)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        try? rslider.setInput("FillPercent", value: uislider.value * 100)
    }
}

class RSlider: RViewModel, RTouchDelegate {
    init() {
        let model = RModel(fileName: "riveslider7", stateMachineName: "Slide")
        super.init(model)
    }
    
    override func configure(rview view: RView) {
        super.configure(rview: view)
        rview?.touchDelegate = self
    }
    
    func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) { }
    
    func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) {
        let percent = Float(location.x / rview!.frame.width) * 100
        try? setInput("FillPercent", value: percent)
    }
    
    func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) { }
    
    func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint) { }
}
