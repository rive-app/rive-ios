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
    var direction = Direction.directionAuto
    
    override public func loadView() {
        super.loadView()
        
        guard let loopModeView = view as? LoopMode else {
            fatalError("Could not find LayoutView")
        }
        try? loopModeView.riveView.configure(
            getRiveFile(resourceName: loopResourceName),
            andAutoPlay: false
        )
        
        loopModeView.triggeredResetButton = {
            try? loopModeView.riveView.reset()
            
            // TODO: just calling reset on an existing file is really not so hot.
            try? loopModeView.riveView.configure(
                getRiveFile(resourceName: self.loopResourceName),
                andAutoPlay: false
            )
        }
        loopModeView.triggeredForwardsButton = {
            self.direction = Direction.directionForwards
        }
        loopModeView.triggeredAutoButton = {
            self.direction = Direction.directionAuto
        }
        loopModeView.triggeredBackwardsButton = {
            self.direction = Direction.directionBackwards
        }
        
        loopModeView.triggeredRotatePlayButton = {
            try? loopModeView.riveView.play(animationName:"oneshot", direction: self.direction)
        }
        loopModeView.triggeredRotateOneShotButton = {
            try? loopModeView.riveView.play(animationName:"oneshot", loop: Loop.loopOneShot, direction: self.direction)
        }
        loopModeView.triggeredRotateLoopButton = {
            try? loopModeView.riveView.play(animationName:"oneshot", loop: Loop.loopLoop, direction: self.direction)
        }
        loopModeView.triggeredRotatePingPongButton = {
            try? loopModeView.riveView.play(animationName:"oneshot", loop: Loop.loopPingPong, direction: self.direction)
        }
        
        loopModeView.triggeredLoopDownPlayButton = {
            try? loopModeView.riveView.play(animationName:"loop", direction: self.direction)
        }
        loopModeView.triggeredLoopDownOneShotButton = {
            try? loopModeView.riveView.play(animationName:"loop", loop: Loop.loopOneShot, direction: self.direction)
        }
        loopModeView.triggeredLoopDownLoopButton = {
            try? loopModeView.riveView.play(animationName:"loop", loop: Loop.loopLoop, direction: self.direction)
        }
        loopModeView.triggeredLoopDownPingPongButton = {
            try? loopModeView.riveView.play(animationName:"loop", loop: Loop.loopPingPong, direction: self.direction)
        }
        
        loopModeView.triggeredLtrPlayButton = {
            try? loopModeView.riveView.play(animationName:"pingpong", direction: self.direction)
        }
        loopModeView.triggeredLtrLoopButton = {
            try? loopModeView.riveView.play(animationName:"pingpong", loop: Loop.loopLoop, direction: self.direction)
        }
        loopModeView.triggeredLtrOneShotButton = {
            try? loopModeView.riveView.play(animationName:"pingpong", loop: Loop.loopOneShot, direction: self.direction)
        }
        loopModeView.triggeredLtrPingPongButton = {
            try? loopModeView.riveView.play(animationName:"pingpong", loop: Loop.loopPingPong, direction: self.direction)
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (view as! LoopMode).triggeredResetButton = nil
        (view as! LoopMode).triggeredForwardsButton = nil
        (view as! LoopMode).triggeredAutoButton = nil
        (view as! LoopMode).triggeredBackwardsButton = nil
        
        (view as! LoopMode).triggeredRotatePlayButton = nil
        (view as! LoopMode).triggeredRotateOneShotButton = nil
        (view as! LoopMode).triggeredRotateLoopButton = nil
        (view as! LoopMode).triggeredRotatePingPongButton = nil
        
        (view as! LoopMode).triggeredLoopDownPlayButton = nil
        (view as! LoopMode).triggeredLoopDownOneShotButton = nil
        (view as! LoopMode).triggeredLoopDownLoopButton = nil
        (view as! LoopMode).triggeredLoopDownPingPongButton = nil
        
        (view as! LoopMode).triggeredLtrPlayButton = nil
        (view as! LoopMode).triggeredLtrLoopButton = nil
        (view as! LoopMode).triggeredLtrOneShotButton = nil
        (view as! LoopMode).triggeredLtrPingPongButton = nil
    }
}

