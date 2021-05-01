//
//  RiveViewController.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

public class RiveViewController: UIViewController {

    var resourceName: String?
    var resourceExt: String?
    var fit: Fit = Fit.Contain
    var alignment: Alignment = Alignment.Center
    var artboardName: String? = nil
    var animationName: String? = nil
    
    var artboard: RiveArtboard?
    var instance: RiveLinearAnimationInstance?
    var displayLink: CADisplayLink?
    var lastTime: CFTimeInterval = 0
    
    public init(
        withResource name: String,
        withExtension ext: String = ".riv",
        withFit fit: Fit = Fit.Contain,
        withAlignment alignment: Alignment = Alignment.Center,
        withArtboardName artboardName: String? = nil,
        withAnimationName animationName: String? = nil
    ) {
        resourceName = name
        resourceExt = ext
        self.fit = fit
        self.alignment = alignment
        self.artboardName = artboardName
        self.animationName = animationName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startRive()
    }
    
    override public func loadView() {
        // Wire up an instance of RiveView to the controller
        let view = RiveView()
        // view.backgroundColor = UIColor.blue
        self.view = view
    }
    
    func startRive() {
        guard let name = resourceName, let ext = resourceExt else {
            fatalError("No resource or extension name specified")
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            fatalError("Failed to locate \(name) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer) in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            
            var errorMsg: String
            if let artboardName = self.artboardName {
                self.artboard = riveFile.artboard(fromName: artboardName)
                errorMsg = "No artboard with \(artboardName) exists"
            } else {
                self.artboard = riveFile.artboard()
                errorMsg = "No default artboard exists"
            }
            
            guard let artboard = self.artboard else {
                fatalError(errorMsg)
            }
                        
            // update the artboard in the view
            (self.view as! RiveView).updateArtboard(
                withArtboard: artboard,
                withFit: fit,
                withAlignment: alignment)
            
            if (artboard.animationCount() == 0) {
                fatalError("No animations in the file.")
            }
                
            let animation: RiveLinearAnimation?
            if let animationName = self.animationName {
                animation = artboard.animation(fromName: animationName)
                errorMsg = "No animation \(animationName) exists in this artboard"
            } else {
                animation = artboard.animation(from: 0)
                errorMsg = "No animations in this artboard"
            }
            
            if (animation == nil) {
                fatalError(errorMsg)
            }
            
            self.instance = animation!.instance()
            
            // Advance the artboard, this will ensure the first
            // frame is displayed when the artboard is drawn
            artboard.advance(by: 0)
            
            // Start the animation loop
            runTimer()
        }
    }
    
    // Starts the animation timer
    func runTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick));
        displayLink?.add(to: .main, forMode: .default)
    }
    
    // Stops the animation timer
    func stopTimer() {
        displayLink?.remove(from: .main, forMode: .default)
    }
    
    // Animates a frame
    @objc func tick() {
        guard let displayLink = displayLink, let artboard = artboard else {
            // Something's gone wrong, clean up and bug out
            stopTimer()
            return
        }
        
        let timestamp = displayLink.timestamp
        // last time needs to be set on the first tick
        if (lastTime == 0) {
            lastTime = timestamp
        }
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime;
        lastTime = timestamp;
        
        // Advance the animation instance and the artboard
        instance!.advance(by: elapsedTime) // advance the animation
        instance!.apply(to: artboard)      // apply to the artboard
                
        artboard.advance(by: elapsedTime) // advance the artboard
        
        // Trigger a redraw
        self.view.setNeedsDisplay()
    }
}
