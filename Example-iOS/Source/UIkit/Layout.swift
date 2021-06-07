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
    
    @IBOutlet weak var riveView: RiveView!
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
            var fit: Fit = .fitContain
            switch name {
            case "Fill":
                fit = .fitFill
            case "Contain":
                fit = .fitContain
            case "Cover":
                fit = .fitCover
            case "Fit Width":
                fit = .fitFitWidth
            case "Fit Height":
                fit = .fitFitHeight
            case "Scale Down":
                fit = .fitScaleDown
            case "None":
                fit = .fitNone
            default:
                fit = .fitContain
            }
            
            layoutView.riveView.fit = fit
        }
        
        func setAlignmnet(name:String) { 
            var alignment: Alignment = .alignmentCenter
            switch name {
            case "Top Left":
                alignment = .alignmentTopLeft
            case "Top Center":
                alignment = .alignmentTopCenter
            case "Top Right":
                alignment = .alignmentTopRight
            case "Center Left":
                alignment = .alignmentCenterLeft
            case "Center":
                alignment = .alignmentCenter
            case "Center Right":
                alignment = .alignmentCenterRight
            case "Bottom Left":
                alignment = .alignmentBottomLeft
            case "Bottom Center":
                alignment = .alignmentBottomCenter
            case "Bottom Right":
                alignment = .alignmentBottomRight
            default:
                alignment = .alignmentCenter
            }
            layoutView.riveView.alignment = alignment
        }
        
        layoutView.fitButtonAction = setFit
        layoutView.alignmentButtonAction = setAlignmnet
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (view as! LayoutView).riveView.stop()
        (view as! LayoutView).fitButtonAction = nil
        (view as! LayoutView).alignmentButtonAction = nil
    }
}
