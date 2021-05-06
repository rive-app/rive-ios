//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

public class RiveView: UIView {
    
    var displayLink: CADisplayLink?
    
    var fit = Fit.Contain
    var alignment = Alignment.Center
    
    var riveFile: RiveFile?
    
    var artboard: RiveArtboard?
    
    var animations: [RiveLinearAnimationInstance] = []
    var playingAnimations: Set<RiveLinearAnimationInstance> = []
    var stateMachines: [RiveStateMachineInstance] = []
    var playingStateMachines: Set<RiveStateMachineInstance> = []
    
    var autoPlay: Bool = true
    var lastTime: CFTimeInterval = 0
    
    
    func isPlaying() -> Bool {
        return !playingAnimations.isEmpty || !playingStateMachines.isEmpty
    }
    
    open func setFit(fit: Fit){
        self.fit = fit
    }
    open func setAlignment(alignment: Alignment){
        self.alignment = alignment
    }

    /*
     * Updates the artboard and layout options
     */
    open func configure(
        withRiveFile riveFile: RiveFile,
        andArtboard artboard: String?=nil,
        andAnimation animation: String?=nil
    ) {
        self.riveFile = riveFile
        
        if let artboardName = artboard {
            self.artboard = riveFile.artboard(fromName:artboardName)
        }else {
            self.artboard = riveFile.artboard()
        }
        
        guard let artboard = self.artboard else {
            fatalError("No default artboard exists")
        }
        
        if (artboard.animationCount() == 0) {
            fatalError("No animations in the file.")
        }
        
        var linearAnimation: RiveLinearAnimation?
        if let animationName = animation {
            linearAnimation = artboard.animation(fromName: animationName)
        }else {
            linearAnimation = artboard.firstAnimation()
        }
        
        if let thisLinearAnimation=linearAnimation {
            animations.append(thisLinearAnimation.instance())
        }
        else {
            fatalError("Animation not found in file.")
        }
        
        // Advance the artboard, this will ensure the first
        // frame is displayed when the artboard is drawn
        artboard.advance(by: 0)
        
        // Start the animation loop
        if autoPlay {
            animations.forEach{ animation in
                playingAnimations.insert(animation)
            }
            
        }
        runTimer()
    }
    
    /*
     * Creates a Rive renderer and applies the currently animating artboard to it
     */
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: alignment, with: fit)
        artboard.draw(renderer)
    }
    
    // Starts the animation timer
    func runTimer() {
        if (displayLink == nil){
            displayLink = CADisplayLink(target: self, selector: #selector(tick));
        }
        displayLink?.add(to: .main, forMode: .default)
    }
    
    // Stops the animation timer
    func stopTimer() {
        displayLink?.remove(from: .main, forMode: .default)
    }
    
    
    // Animates a frame
    @objc func tick() {
        guard let displayLink = displayLink else {
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
        advance(delta: elapsedTime)
        if(!isPlaying()){
            stopTimer()
        }
    }
    
    func advance(delta:Double){
        guard let artboard = artboard else {
            return
        }
        animations.forEach{ animation in
            if playingAnimations.contains(animation){
                let stillPlaying = animation.advance(by: delta)
                animation.apply(to: artboard)
                if !stillPlaying {
                    playingAnimations.remove(animation)
                }
            }
        }
        stateMachines.forEach{ stateMachine in
            if playingStateMachines.contains(stateMachine){
                let stillPlaying = stateMachine.advance(by: delta)
                stateMachine.apply(to: artboard)
                if !stillPlaying {
                    playingStateMachines.remove(stateMachine)
                }
            }
        }
        // advance the artboard
        artboard.advance(by: delta)
        // Trigger a redraw
        self.setNeedsDisplay()
    }
}
