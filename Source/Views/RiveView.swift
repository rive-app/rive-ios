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
    
    public init(riveFile: RiveFile, fit: Fit = Fit.Contain, alignment: Alignment = Alignment.Center) {
        super.init(frame: .zero)
        self.configure(withRiveFile: riveFile)
        setFit(fit: fit)
        setAlignment(alignment: alignment)
    }
    
    public init() {
      super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
    
    
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
        andAnimation animation: String?=nil,
        andAutoPlay autoPlay: Bool=true
    ) {
        self.riveFile = riveFile
        self.autoPlay = autoPlay
        
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
        
        // Advance the artboard, this will ensure the first
        // frame is displayed when the artboard is drawn
        artboard.advance(by: 0)
        
        // Start the animation loop
        if autoPlay {
            if let animationName = animation {
                play(animationName: animationName)
            }else {
                play()
            }
        }
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
            // Note: common didnt pause on scroll.
            displayLink?.add(to: .main, forMode: .common)
        }
        if (displayLink?.isPaused==true){
            lastTime=0
            displayLink!.isPaused=false
        }
    }
    
    // Stops the animation timer
    func stopTimer() {
        // should we pause or invalidate?
        displayLink?.isPaused=true
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
                    if (animation.animation().loop() == Loop.LoopOneShot.rawValue) {
                        animations.removeAll(where: {animationInstance in
                            return animationInstance == animation
                        })
                    }
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
    
    public func play(
        loop: Loop = Loop.LoopAuto,
        direction: Direction = Direction.DirectionAuto
    ) {
        guard let guardedArtboard=artboard else {
            return;
        }
        
        _playAnimation(
            animationName:guardedArtboard.firstAnimation().name(),
            loop:loop,
            direction:direction
        )
        runTimer()
    }
    
    
    public func play(
        animationName: String,
        loop: Loop = Loop.LoopAuto,
        direction: Direction = Direction.DirectionAuto,
        isStateMachine: Bool = false
    ) {
        _playAnimation(
            animationName:animationName,
            loop:loop,
            direction:direction,
            isStateMachine:isStateMachine
        )
        runTimer()
    }
    
    private func _playAnimation(
            animationName: String,
            loop: Loop = Loop.LoopAuto,
            direction: Direction = Direction.DirectionAuto,
            isStateMachine: Bool = false
        )
    {
        if (isStateMachine) {
//                val stateMachineInstances = _getOrCreateStateMachines(animationName)
//                stateMachineInstances.forEach { stateMachineInstance ->
//                    _play(stateMachineInstance)
//                }
        } else {
            let animationInstances = _animations(animationName: animationName)
            
            animationInstances.forEach { animationInstance in
                _play(
                    animation:animationInstance,
                    loop:loop, direction:direction
                )
            }
            if (animationInstances.isEmpty) {
                guard let guardedArtboard=artboard else {
                    return
                }
                let animationInstance = guardedArtboard.animation(fromName:animationName).instance()
                    
                _play(animation:animationInstance, loop:loop, direction:direction)

            }
        }
    }
        
    
    private func _animations(animationName: String)->[RiveLinearAnimationInstance] {
        return _animations(animationNames:[animationName])
    }
    
    private func _animations(animationNames: [String])-> [RiveLinearAnimationInstance] {
        return animations.filter {  animationInstance in
            animationNames.contains(animationInstance.animation().name())
        }
    }

    private func _play(
        animation animationInstance: RiveLinearAnimationInstance,
        loop: Loop,
        direction: Direction
    ) {
        if (loop != Loop.LoopAuto) {
            animationInstance.animation().loop(Int32(loop.rawValue))
        }
        if (!animations.contains(animationInstance)) {
            if (direction == Direction.DirectionBackwards) {
                animationInstance.setTime(animationInstance.animation().endTime())
            }
            animations.append(
                animationInstance
            )
        }
        if (direction == Direction.DirectionForwards) {
            animationInstance.direction(1)
        }else if (direction == Direction.DirectionBackwards) {
            animationInstance.direction(-1)
        }
    
        playingAnimations.insert(animationInstance)
        //        notifyPlay(animationInstance)
    }
}
