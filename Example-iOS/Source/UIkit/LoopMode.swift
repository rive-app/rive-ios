//
//  LoopMode.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 07/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class LoopMode: UIView {
    typealias ButtonAction = ()->Void
    @IBOutlet var riveView: RiveView!
    
    @IBAction func resetButton(_ sender: Any) {
        triggeredResetButton?()
    }
    @IBAction func forwardsButton(_ sender: Any){
        triggeredForwardsButton?()
    }
    @IBAction func autoButton(_ sender: Any){
        triggeredAutoButton?()
    }
    @IBAction func backwardsButton(_ sender: Any){
        triggeredBackwardsButton?()
    }
    
    @IBAction func rotatePlayButton(_ sender: Any){
        triggeredRotatePlayButton?()
    }
    @IBAction func rotateOneShotButton(_ sender: Any){
        triggeredRotateOneShotButton?()
    }
    @IBAction func rotateLoopButton(_ sender: Any){
        triggeredRotateLoopButton?()
    }
    @IBAction func rotatePingPongButton(_ sender: Any){
        triggeredRotatePingPongButton?()
    }
    
    @IBAction func loopDownPlayButton(_ sender: Any){
        triggeredLoopDownPlayButton?()
    }
    @IBAction func loopDownOneShotButton(_ sender: Any){
        triggeredLoopDownOneShotButton?()
    }
    @IBAction func loopDownLoopButton(_ sender: Any){
        triggeredLoopDownLoopButton?()
    }
    @IBAction func loopDownPingPongButton(_ sender: Any){
        triggeredLoopDownPingPongButton?()
    }
    
    @IBAction func ltrPlayButton(_ sender: Any){
        triggeredLtrPlayButton?()
    }
    @IBAction func ltrOneShotButton(_ sender: Any){
        triggeredLtrOneShotButton?()
    }
    @IBAction func ltrLoopButton(_ sender: Any){
        triggeredLtrLoopButton?()
    }
    @IBAction func ltrPingPongButton(_ sender: Any){
        triggeredLtrPingPongButton?()
    }
    
    var triggeredResetButton: ButtonAction?
    var triggeredForwardsButton: ButtonAction?
    var triggeredAutoButton: ButtonAction?
    var triggeredBackwardsButton: ButtonAction?
    
    var triggeredRotatePlayButton: ButtonAction?
    var triggeredRotateOneShotButton: ButtonAction?
    var triggeredRotateLoopButton: ButtonAction?
    var triggeredRotatePingPongButton: ButtonAction?
    
    var triggeredLoopDownPlayButton: ButtonAction?
    var triggeredLoopDownOneShotButton: ButtonAction?
    var triggeredLoopDownLoopButton: ButtonAction?
    var triggeredLoopDownPingPongButton: ButtonAction?
    
    var triggeredLtrPlayButton: ButtonAction?
    var triggeredLtrOneShotButton: ButtonAction?
    var triggeredLtrLoopButton: ButtonAction?
    var triggeredLtrPingPongButton: ButtonAction?
    
}

class LoopModeController: UIViewController {
    let loopResourceName = "loopy"
    var direction = Direction.DirectionAuto
    
    override public func loadView() {
        super.loadView()
        
        guard let loopModeView = view as? LoopMode else {
            fatalError("Could not find LayoutView")
        }
        
        loopModeView.riveView.configure(
            withRiveFile: getRiveFile(resourceName: loopResourceName),
            andAutoPlay: false
        )
        
        loopModeView.triggeredResetButton = {
            loopModeView.riveView.reset()
            
            // TODO: just calling reset on an existing file is really not so hot.
            loopModeView.riveView.configure(
                withRiveFile: getRiveFile(resourceName: self.loopResourceName),
                andAutoPlay: false
            )
        }
        loopModeView.triggeredForwardsButton = {
            self.direction = Direction.DirectionForwards
        }
        loopModeView.triggeredAutoButton = {
            self.direction = Direction.DirectionAuto
        }
        loopModeView.triggeredBackwardsButton = {
            self.direction = Direction.DirectionBackwards
        }
        
        loopModeView.triggeredRotatePlayButton = {
            loopModeView.riveView.play(animationName:"oneshot", direction: self.direction)
        }
        loopModeView.triggeredRotateOneShotButton = {
            loopModeView.riveView.play(animationName:"oneshot", loop: Loop.LoopOneShot, direction: self.direction)
        }
        loopModeView.triggeredRotateLoopButton = {
            loopModeView.riveView.play(animationName:"oneshot", loop: Loop.LoopLoop, direction: self.direction)
        }
        loopModeView.triggeredRotatePingPongButton = {
            loopModeView.riveView.play(animationName:"oneshot", loop: Loop.LoopPingPong, direction: self.direction)
        }
        
        loopModeView.triggeredLoopDownPlayButton = {
            loopModeView.riveView.play(animationName:"loop", direction: self.direction)
        }
        loopModeView.triggeredLoopDownOneShotButton = {
            loopModeView.riveView.play(animationName:"loop", loop: Loop.LoopOneShot, direction: self.direction)
        }
        loopModeView.triggeredLoopDownLoopButton = {
            loopModeView.riveView.play(animationName:"loop", loop: Loop.LoopLoop, direction: self.direction)
        }
        loopModeView.triggeredLoopDownPingPongButton = {
            loopModeView.riveView.play(animationName:"loop", loop: Loop.LoopPingPong, direction: self.direction)
        }
        
        loopModeView.triggeredLtrPlayButton = {
            loopModeView.riveView.play(animationName:"pingpong", direction: self.direction)
        }
        loopModeView.triggeredLtrLoopButton = {
            loopModeView.riveView.play(animationName:"pingpong", loop: Loop.LoopLoop, direction: self.direction)
        }
        loopModeView.triggeredLtrOneShotButton = {
            loopModeView.riveView.play(animationName:"pingpong", loop: Loop.LoopOneShot, direction: self.direction)
        }
        loopModeView.triggeredLtrPingPongButton = {
            loopModeView.riveView.play(animationName:"pingpong", loop: Loop.LoopPingPong, direction: self.direction)
        }

        
    }
}

