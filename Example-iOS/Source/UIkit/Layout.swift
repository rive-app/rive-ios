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
    let resourceExt = ".riv"
    
    
    func getRiveFile() -> RiveFile {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) else {
            fatalError("Failed to locate \(resourceName) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        return data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer)->RiveFile in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            return riveFile
        }
    }
    
    override public func loadView() {
        super.loadView()
        
        guard let layoutView = view as? LayoutView else {
            fatalError("What")
        }
        
        layoutView.riveView.configure(withRiveFile: getRiveFile())
        
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
            layoutView.riveView.setFit(fit:fit)
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
            layoutView.riveView.setAlignment(alignment:alignment)
        }
        
        layoutView.fitButtonAction = setFit
        layoutView.alignmentButtonAction = setAlignmnet
    }
}
