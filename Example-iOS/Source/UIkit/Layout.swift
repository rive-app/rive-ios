//
//  Layout.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class LayoutView: UIView {
    typealias ButtonAction = (String)->Void
    var fitButtonAction: ButtonAction?
    var alignmentButtonAction: ButtonAction?
    
    @IBOutlet var riveView: RiveView!
    
    
    @IBAction func fitButtonTriggered(_ sender: UIButton) {
        fitButtonAction?(sender.currentTitle!)
    }
    
    @IBAction func alignmentButtonTriggered(_ sender: UIButton) {
        alignmentButtonAction?(sender.currentTitle!)
    }
}

class LayoutViewController: UIViewController {
    let resourceName = "truck_v7"
    
    override public func loadView() {
        super.loadView()
        
        guard let layoutView = view as? LayoutView else {
            fatalError("Could not find LayoutView")
        }
        
        layoutView.riveView.configure(getRiveFile(resourceName: resourceName))
        
        func setFit(name:String) {
            var fit: Fit = .contain
            switch name {
            case "Fill":
                fit = .fill
            case "Contain":
                fit = .contain
            case "Cover":
                fit = .cover
            case "Fit Width":
                fit = .fitWidth
            case "Fit Height":
                fit = .fitHeight
            case "Scale Down":
                fit = .scaleDown
            case "None":
                fit = .none
            default:
                fit = .contain
            }
            layoutView.riveView.fit = fit
        }
        
        func setAlignmnet(name:String) {
            var alignment: Alignment = .center
            switch name {
            case "Top Left":
                alignment = .topLeft
            case "Top Center":
                alignment = .topCenter
            case "Top Right":
                alignment = .topRight
            case "Center Left":
                alignment = .centerLeft
            case "Center":
                alignment = .center
            case "Center Right":
                alignment = .centerRight
            case "Bottom Left":
                alignment = .bottomLeft
            case "Bottom Center":
                alignment = .bottomCenter
            case "Bottom Right":
                alignment = .bottomRight
            default:
                alignment = .center
            }
            layoutView.riveView.alignment = alignment
        }
        
        layoutView.fitButtonAction = setFit
        layoutView.alignmentButtonAction = setAlignmnet
    }
}
