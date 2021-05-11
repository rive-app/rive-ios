//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

// Signature for a loop action delegate function
public typealias LoopAction = ((String, Int) -> Void)?

// Delegate for handling loop events
public protocol LoopDelegate: AnyObject {
    func loop(_ animationName: String, type: Int)
}

// signature for a play action delegate function
public typealias PlaybackAction = ((String) -> Void)?

// Delegate for handling play action
public protocol PlayDelegate: AnyObject {
    func play(_ animationName: String)
}

// Delegate for handling pause action
public protocol PauseDelegate: AnyObject {
    func pause(_ animationName: String)
}

/// Playback states for a Rive file
public enum Playback {
    case play
    case pause
    case stop
}

public class RiveView: UIView {
    
    var displayLink: CADisplayLink?
    
    // Queue of events that need to be done outside view updates
    private var eventQueue = EventQueue()
    
    private var _fit = Fit.Contain
    
    open var fit: Fit {
        set {
            _fit = newValue
            // Advance the artboard if there's one so that Rive redraws with the new fit
            // TODO: this does nothing when animations are paused as they're skipped for drawing
            artboard?.advance(by: 0)
        }
        get { return _fit }
    }
    
    private var _alignment = Alignment.Center
    
    open var alignment: Alignment {
        set {
            _alignment = newValue
            // Advance the artboard if there's one so that Rive redraws with the new alignment
            // TODO: this does nothing when animations are paused as they're skipped for drawing
            artboard?.advance(by: 0)
        }
        get { return _alignment }
    }
    
    var isPlaying: Bool {
        get { return !playingAnimations.isEmpty || !playingStateMachines.isEmpty }
    }
    
    open var playback: Playback {
        get { return isPlaying ? Playback.play : Playback.pause }
        set {
            if newValue == Playback.play {
                play()
            } else {
                pause()
            }
        }
    }
    
    var riveFile: RiveFile?
    
    var artboard: RiveArtboard?
    
    var animations: [RiveLinearAnimationInstance] = []
    var playingAnimations: Set<RiveLinearAnimationInstance> = []
    var stateMachines: [RiveStateMachineInstance] = []
    var playingStateMachines: Set<RiveStateMachineInstance> = []
    
    var autoPlay: Bool = true
    var lastTime: CFTimeInterval = 0
    
    // Delegates
    public weak var loopDelegate: LoopDelegate?
    public weak var playDelegate: PlayDelegate?
    public weak var pauseDelegate: PauseDelegate?
    
    public init(
        riveFile: RiveFile,
        fit: Fit = Fit.Contain,
        alignment: Alignment = Alignment.Center,
        autoplay: Bool = true,
        loopDelegate: LoopDelegate? = nil,
        playDelegate: PlayDelegate? = nil,
        pauseDelegate: PauseDelegate? = nil
    ) {
        super.init(frame: .zero)
        self.fit = fit
        self.alignment = alignment
        self.loopDelegate = loopDelegate
        self.playDelegate = playDelegate
        self.configure(withRiveFile: riveFile, andAutoPlay: autoplay)
    }
    
    public init() {
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

        
    @objc func animationWillMoveToBackground() {
        print("Triggers when app is moving to background")
    }
    
    @objc func animationWillEnterForeground() {
        print("Triggers when app is moving to foreground")
    }
    
    /*
     * Updates the artboard and layout options
     */
    open func configure(
        withRiveFile riveFile: RiveFile,
        andArtboard artboard: String?=nil,
        andAnimation animation: String?=nil,
        andStateMachine stateMachine: String?=nil,
        andAutoPlay autoPlay: Bool=true
    ) {
        // Testing stuff
        NotificationCenter.default.addObserver(self, selector: #selector(animationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animationWillMoveToBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Ensure the view's transparent
        self.isOpaque = false
        
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
        // artboard.advance(by: 0)
        
        // Start the animation loop
        if autoPlay {
            if let animationName = animation {
                play(animationName: animationName)
            }else if let stateMachineName = stateMachine {
                play(animationName: stateMachineName, isStateMachine: true)
            }else {
                play()
            }
        }else {
            advance(delta: 0)
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
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(tick));
            // Note: common didnt pause on scroll.
            displayLink?.add(to: .main, forMode: .common)
        }
        if displayLink?.isPaused == true {
            lastTime = 0
            displayLink!.isPaused = false
        }
    }
    
    // Stops the animation timer
    func stopTimer() {
        // should we pause or invalidate?
        displayLink?.isPaused = true
    }
    
    func clear() {
        playingAnimations.removeAll()
        playingStateMachines.removeAll()
        animations.removeAll()
        stateMachines.removeAll()
        stopTimer()
        lastTime = 0
    }
    
    public func reset() {
        clear()
        stopTimer()
        if let riveFile = self.riveFile {
            // TODO: this is totally not enough to reset the file. i guess its because the file's artboard is already changed.
            configure(withRiveFile: riveFile, andAutoPlay: autoPlay)
        }
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
        if lastTime == 0 {
            lastTime = timestamp
        }
        
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime;
        lastTime = timestamp;
        advance(delta: elapsedTime)
        if(!isPlaying){
            stopTimer()
        }
    }
    
    func advance(delta:Double) {
        guard let artboard = artboard else {
            return
        }
        
        // Testing firing events here
        eventQueue.fireAll()
        
        animations.forEach{ animation in
            if playingAnimations.contains(animation) {
                let stillPlaying = animation.advance(by: delta)
                animation.apply(to: artboard)
                if !stillPlaying {
                    playingAnimations.remove(animation)
                    if (animation.loop() == Loop.LoopOneShot.rawValue) {
                        animations.removeAll(where: { animationInstance in
                            return animationInstance == animation
                        })
                    }
                }
                // Check if the animation looped and if so, call the delegate
                if animation.didLoop() {
                    loopDelegate?.loop(animation.name(), type: Int(animation.loop()))
                }
            }
        }
        stateMachines.forEach{ stateMachine in
            if playingStateMachines.contains(stateMachine) {
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
    
    /// Plays the specified animation or state machine with optional loop and directions
    /// - Parameter animationName: name of the animation to play
    /// - Parameter loop: overrides the animation's loop setting
    /// - Parameter direction: overrides the animation's default direction (forwards)
    /// - Parameter isStateMachine: true of the name refers to a state machine and not an animation
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
    
    /// Pauses all playing animations and state machines
    public func pause() {
        playingAnimations.forEach { animation in _pause(animation) }
        playingStateMachines.forEach { stateMachine in _pause(stateMachine) }
    }
    
    private func _getOrCreateStateMachines(
        animationName: String
    ) -> [RiveStateMachineInstance]{
        let stateMachineInstances = _stateMachines(animationName: animationName)
        if (stateMachineInstances.isEmpty){
            guard let guardedArtboard=artboard else {
                return []
            }
            let stateMachineInstance = guardedArtboard.stateMachine(fromName: animationName).instance()
            return [stateMachineInstance]
        }
        return stateMachineInstances
    }
    
    private func _playAnimation(
            animationName: String,
            loop: Loop = Loop.LoopAuto,
            direction: Direction = Direction.DirectionAuto,
            isStateMachine: Bool = false
        )
    {
        if (isStateMachine) {
            let stateMachineInstances = _getOrCreateStateMachines(animationName:animationName)
            stateMachineInstances.forEach { stateMachineInstance in
                _play(stateMachineInstance)
            }
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
    
    private func _stateMachines(animationName: String)->[RiveStateMachineInstance] {
        return _stateMachines(animationNames:[animationName])
    }
    
    private func _stateMachines(animationNames: [String])-> [RiveStateMachineInstance] {
        return stateMachines.filter {  stateMachineInstance in
            animationNames.contains(stateMachineInstance.stateMachine().name())
        }
    }

    private func _play(
        animation animationInstance: RiveLinearAnimationInstance,
        loop: Loop,
        direction: Direction
    ) {
        if (loop != Loop.LoopAuto) {
            animationInstance.loop(Int32(loop.rawValue))
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
        eventQueue.add( { self.playDelegate?.play(animationInstance.name()) } )
    }
        
    /// Pauses a playing animation
    ///
    /// - Parameter animation: the animation to pause
    private func _pause(_ animation: RiveLinearAnimationInstance) {
        let removed = playingAnimations.remove(animation)
        if removed != nil {
            eventQueue.add( { self.pauseDelegate?.pause(animation.name()) } )
        }
    }
    
    private func _play(_ stateMachineInstance: RiveStateMachineInstance) {
        if (!stateMachines.contains(stateMachineInstance)) {
            stateMachines.append(
                stateMachineInstance
            )
        }
    
        playingStateMachines.insert(stateMachineInstance)
        eventQueue.add( { self.playDelegate?.play(stateMachineInstance.name()) } )
    }
    
    /// Pauses a playing state machine
    ///
    /// - Parameter stateMachine: the state machine to pause
    private func _pause(_ stateMachine: RiveStateMachineInstance) {
        let removed = playingStateMachines.remove(stateMachine)
        if removed != nil {
            eventQueue.add( { self.pauseDelegate?.pause(stateMachine.name()) } )
        }
    }
    
    open func fireState(stateMachineName: String, inputName: String) {
        let stateMachineInstances = _getOrCreateStateMachines(animationName: stateMachineName)
        stateMachineInstances.forEach { stateMachine in
            stateMachine.getTrigger(inputName).fire()
            _play(stateMachine)
        }
        runTimer()
    }

    open func setBooleanState(stateMachineName: String, inputName: String, value: Bool) {
        let stateMachineInstances = _getOrCreateStateMachines(animationName: stateMachineName)
        stateMachineInstances.forEach { stateMachine in
            stateMachine.getBool(inputName).setValue(value)
            _play(stateMachine)
        }
        runTimer()
    }

    open func setNumberState(stateMachineName: String, inputName: String, value: Float) {
        let stateMachineInstances = _getOrCreateStateMachines(animationName: stateMachineName)
        stateMachineInstances.forEach { stateMachine in
            stateMachine.getNumber(inputName).setValue(value)
            _play(stateMachine)
        }
        runTimer()
    }

}


// Tracks a queue of events that haven't been fired yet. We do this so
// that we're not calling delegates and modifying state while a view is
// updating (e.g. being initialized, as we autoplay and fire play events
// during the view's init otherwise
class EventQueue {
    var events:[() -> Void] = []
    
    func add(_ event: @escaping () -> Void) {
        events.append(event)
    }
    
    func fireAll() {
        events.forEach { event in
            event()
        }
        events.removeAll()
    }
}
