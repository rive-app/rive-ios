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
        var fit: RiveFit = .contain
        switch name {
        case "Fill": fit = .fill
        case "Contain": fit = .contain
        case "Cover": fit = .cover
        case "Fit Width": fit = .fitWidth
        case "Fit Height": fit = .fitHeight
        case "Scale Down": fit = .scaleDown
        case "None": fit = .noFit
        default: fit = .contain
        }
        viewModel.fit = fit
    }
    
    func setAlignment(name: String = "") {
        var alignment: RiveAlignment = .center
        switch name {
        case "Top Left": alignment = .topLeft
        case "Top Center": alignment = .topCenter
        case "Top Right": alignment = .topRight
        case "Center Left": alignment = .centerLeft
        case "Center": alignment = .center
        case "Center Right": alignment = .centerRight
        case "Bottom Left": alignment = .bottomLeft
        case "Bottom Center": alignment = .bottomCenter
        case "Bottom Right": alignment = .bottomRight
        default: alignment = .center
        }
        viewModel.alignment = alignment
    }
}
