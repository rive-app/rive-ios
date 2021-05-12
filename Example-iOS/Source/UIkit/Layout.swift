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
        
        func setFit(name:String){
            var fit = Fit.Contain
            switch name {
            case "Fill":
                fit = Fit.Fill
            case "Contain":
                fit = Fit.Contain
            case "Cover":
                fit = Fit.Cover
            case "Fit Width":
                fit = Fit.FitWidth
            case "Fit Height":
                fit = Fit.FitHeight
            case "Scale Down":
                fit = Fit.ScaleDown
            case "None":
                fit = Fit.None
            default:
                fit = Fit.Contain
            }
            layoutView.riveView.fit = fit
        }
        
        func setAlignmnet(name:String){
            var alignment = Alignment.Center
            switch name {
            case "Top Left":
                alignment = Alignment.TopLeft
            case "Top Center":
                alignment = Alignment.TopCenter
            case "Top Right":
                alignment = Alignment.TopRight
            case "Center Left":
                alignment = Alignment.CenterLeft
            case "Center":
                alignment = Alignment.Center
            case "Center Right":
                alignment = Alignment.CenterRight
            case "Bottom Left":
                alignment = Alignment.BottomLeft
            case "Bottom Center":
                alignment = Alignment.BottomCenter
            case "Bottom Right":
                alignment = Alignment.BottomRight
            default:
                alignment = Alignment.Center
            }
            layoutView.riveView.alignment = alignment
        }
        
        layoutView.fitButtonAction = setFit
        layoutView.alignmentButtonAction = setAlignmnet
    }
}
