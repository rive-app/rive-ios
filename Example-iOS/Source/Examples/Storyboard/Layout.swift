//
//  Layout.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class LayoutViewController: UIViewController {
    @IBOutlet weak var riveView: RiveView!
    var viewModel = RiveViewModel(fileName: "truck_v7")
    
    override func viewDidLoad() {
        viewModel.setView(riveView)
    }
    
    @IBAction func fitButtonTriggered(_ sender: UIButton) {
        setFit(name: sender.currentTitle!)
    }
    
    @IBAction func alignmentButtonTriggered(_ sender: UIButton) {
        setAlignment(name: sender.currentTitle!)
    }
    
    func setFit(name: String = "") {
        var fit: Fit = .fitContain
        switch name {
        case "Fill": fit = .fitFill
        case "Contain": fit = .fitContain
        case "Cover": fit = .fitCover
        case "Fit Width": fit = .fitFitWidth
        case "Fit Height": fit = .fitFitHeight
        case "Scale Down": fit = .fitScaleDown
        case "None": fit = .fitNone
        default: fit = .fitContain
        }
        viewModel.fit = fit
    }
    
    func setAlignment(name: String = "") {
        var alignment: Alignment = .alignmentCenter
        switch name {
        case "Top Left": alignment = .alignmentTopLeft
        case "Top Center": alignment = .alignmentTopCenter
        case "Top Right": alignment = .alignmentTopRight
        case "Center Left": alignment = .alignmentCenterLeft
        case "Center": alignment = .alignmentCenter
        case "Center Right": alignment = .alignmentCenterRight
        case "Bottom Left": alignment = .alignmentBottomLeft
        case "Bottom Center": alignment = .alignmentBottomCenter
        case "Bottom Right": alignment = .alignmentBottomRight
        default: alignment = .alignmentCenter
        }
        viewModel.alignment = alignment
    }
}
