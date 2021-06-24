//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

/// Signature for a loop action delegate function
public typealias LoopAction = ((String, Int) -> Void)?

/// Delegate for handling loop events
public protocol LoopDelegate: AnyObject {
    func loop(_ animationName: String, type: Int)
}

/// signature for a play action delegate function
public typealias PlaybackAction = ((String) -> Void)?

/// signature for inputs action delegate function
public typealias InputsAction = (([StateMachineInput]) -> Void)?

/// Delegate for handling play action
public protocol PlayDelegate: AnyObject {
    func play(_ animationName: String, isStateMachine: Bool)
}

/// Delegate for handling pause action
public protocol PauseDelegate: AnyObject {
    func pause(_ animationName: String, isStateMachine: Bool)
}

/// Delegate for handling stop action
public protocol StopDelegate: AnyObject {
    func stop(_ animationName: String, isStateMachine: Bool)
}

/// Delegate for reporting changes to available input states
public protocol InputsDelegate: AnyObject {
    func inputs(_ inputs: [StateMachineInput])
}

/// Delegate for new input states
public protocol StateChangeDelegate: AnyObject {
    func stateChange(_ stateMachineName: String, _ stateName: String)
}

/// Playback states for a Rive file
public enum Playback {
    case play
    case pause
    case stop
}

/// State machine input types
public enum StateMachineInputType {
    case trigger
    case number
    case boolean
}

/// Simple data type for passing state machine input names and their types
public struct StateMachineInput: Hashable {
    public let name: String
    public let type: StateMachineInputType
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
        events.forEach { $0() }
        events.removeAll()
    }
}

/// Stores config options for a RiveFile when rive files load async
struct ConfigOptions {
    let riveFile: RiveFile
    var artboard: String? = nil
    var animation: String? = nil
    var stateMachine: String?
    var autoPlay: Bool = true
}


class CADisplayLinkProxy {

    var displayLink: CADisplayLink?
    var handle: (() -> Void)?
    private var runloop: RunLoop
    private var mode: RunLoop.Mode

    init(handle: (() -> Void)?, to runloop: RunLoop, forMode mode: RunLoop.Mode) {
        self.handle = handle
        self.runloop = runloop
        self.mode = mode
        displayLink = CADisplayLink(target: self, selector: #selector(updateHandle))
        displayLink?.add(to: runloop, forMode: mode)
    }

    @objc func updateHandle() {
        handle?()
    }

    func invalidate() {
        displayLink?.remove(from: runloop, forMode: mode)
        displayLink?.invalidate()
        displayLink = nil
    }
}

public class RiveView: UIView {
    
    deinit {
        // print("RiveView is being de initialized")
    }
    
    // Configuration
    private var riveFile: RiveFile?
    private var _fit: Fit = .fitContain
    private var _alignment: Alignment = .alignmentCenter
    private var _artboard: RiveArtboard?
    private var autoPlay: Bool = true
    
    // Playback controls
    public var animations: [RiveLinearAnimationInstance] = []
    public var playingAnimations: Set<RiveLinearAnimationInstance> = []
    public var stateMachines: [RiveStateMachineInstance] = []
    public var playingStateMachines: Set<RiveStateMachineInstance> = []
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: CADisplayLinkProxy?
    
    // Delegates
    public weak var loopDelegate: LoopDelegate?
    public weak var playDelegate: PlayDelegate?
    public weak var pauseDelegate: PauseDelegate?
    public weak var stopDelegate: StopDelegate?
    public weak var inputsDelegate: InputsDelegate?
    public weak var stateChangeDelegate: StateChangeDelegate?
    
    // Tracks config options when rive files load asynchronously
    private var configOptions: ConfigOptions?
    
    // Queue of events that need to be done outside view updates
    private var eventQueue = EventQueue()
    
    /// Constructor with a riveFile.
    /// - Parameters:
    ///   - riveFile: the riveFile to use for the View.
    ///   - fit: to specify how and if the animation should be resized to fit its container.
    ///   - alignment: to specify how the animation should be aligned to its container.
    ///   - autoplay: play as soon as the animaiton is loaded.
    ///   - artboard: determine the `Artboard`to use, by default the first Artboard in the riveFile is picked.
    ///   - animation: determine the `Animation`to play, by default the first Animation/StateMachine in the riveFile is picked.
    ///   - stateMachine: determine the `StateMachine`to play, ignored if `animation` is set. By default the first Animation/StateMachine in the riveFile is picked.
    ///   - loopDelegate: to get callbacks when an `Animation` Loops
    ///   - playDelegate: to get callbacks when an `Animation` or  a `StateMachine`'s playback starts, or restarts.
    ///   - pauseDelegate: to get callbacks when an `Animation` or  a `StateMachine`'s playback pauses.
    ///   - stopDelegate: to get callbacks when an `Animation` or  a `StateMachine` is stopped.
    ///   - inputsDelegate: to get callbacks for inputs relevant to a loaded `StateMachine`.
    ///   - stateChangeDelegate: to get callbacks for when the current state of a StateMachine chagnes.
    public init(
        riveFile: RiveFile,
        fit: Fit = .fitContain,
        alignment: Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        loopDelegate: LoopDelegate? = nil,
        playDelegate: PlayDelegate? = nil,
        pauseDelegate: PauseDelegate? = nil,
        stopDelegate: StopDelegate? = nil,
        inputsDelegate: InputsDelegate? = nil,
        stateChangeDelegate: StateChangeDelegate? = nil
    ) throws {
        super.init(frame: .zero)
        self.fit = fit
        self.alignment = alignment
        self.loopDelegate = loopDelegate
        self.playDelegate = playDelegate
        self.pauseDelegate = pauseDelegate
        self.stopDelegate = stopDelegate
        self.inputsDelegate = inputsDelegate
        self.stateChangeDelegate = stateChangeDelegate
        try self.configure(riveFile, andArtboard: artboard, andAnimation: animation, andStateMachine: stateMachine, andAutoPlay: autoplay)
    }
    
    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// Handle when a Rive file is asynchronously loaded
extension RiveView: RiveFileDelegate {
    public func riveFileDidLoad(_ riveFile: RiveFile) throws {
        try self.configure(riveFile)
    }
}

// MARK:- Configure
extension RiveView {
    /// Configure fit to specify how and if the animation should be resized to fit its container.
    open var fit: Fit {
        set {
            _fit = newValue
            // Advance the artboard if there's one so that Rive redraws with the new fit
            // TODO: this does nothing when animations are paused as they're skipped for drawing
            _artboard?.advance(by: 0)
        }
        get { return _fit }
    }
    
    /// Configure alignment to specify how the animation should be aligned to its container.
    open var alignment: Alignment {
        set {
            _alignment = newValue
            // Advance the artboard if there's one so that Rive redraws with the new alignment
            // TODO: this does nothing when animations are paused as they're skipped for drawing
            _artboard?.advance(by: 0)
        }
        get { return _alignment }
    }

    /// Return the selected `RiveArtboard`.
    open var artboard: RiveArtboard? {
        get { return _artboard }
    }
    
    /// Updates the artboard and layout options
    /// - Parameters:
    ///   - riveFile: <#riveFile description#>
    ///   - artboard: <#artboard description#>
    ///   - animation: <#animation description#>
    ///   - stateMachine: <#stateMachine description#>
    ///   - autoPlay: <#autoPlay description#>
    open func configure(
        _ riveFile: RiveFile,
        andArtboard artboard: String?=nil,
        andAnimation animation: String?=nil,
        andStateMachine stateMachine: String?=nil,
        andAutoPlay autoPlay: Bool=true
    ) throws {
        clear()
        
        // Always save the config options to preserve for reset
        configOptions = ConfigOptions(
            riveFile: riveFile,
            artboard: artboard ?? configOptions?.artboard,
            animation: animation ?? configOptions?.animation,
            stateMachine: stateMachine ?? configOptions?.stateMachine,
            autoPlay: autoPlay // has a default setting
        );
        
        // If it isn't loaded, early out
        if !riveFile.isLoaded {
            return;
        }
        
        
        // Testing stuff
        NotificationCenter.default.addObserver(self, selector: #selector(animationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animationWillMoveToBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Ensure the view's transparent
        self.isOpaque = false
        
        self.riveFile = riveFile
        self.autoPlay = configOptions!.autoPlay
        
        let rootArtboard: RiveArtboard?
        
        if let artboardName = configOptions?.artboard {
            rootArtboard = try riveFile.artboard(fromName:artboardName)
        } else {
            rootArtboard = try riveFile.artboard()
        }
        guard let artboard = rootArtboard else {
            fatalError("No default artboard exists")
        }
        
        if (artboard.animationCount() == 0) {
            fatalError("No animations in the file.")
        }
        
        // Make an instance of the artboard and use that
        self._artboard = artboard.instance();

        // Start the animation loop
        if autoPlay {
            if let animationName = configOptions?.animation {
                try play(animationName: animationName)
            } else if let stateMachineName = configOptions?.stateMachine {
                try play(animationName: stateMachineName, isStateMachine: true)
            } else {
                try play()
            }
        } else {
            advance(delta: 0)
        }
    }
    
    /// Stop playback, clear any created animation or state machine instances.
    private func clear() {
        stop()
        playingAnimations.removeAll()
        playingStateMachines.removeAll()
        animations.removeAll()
        stateMachines.removeAll()
        stopTimer()
        lastTime = 0
    }
    
    /// Returns a list of artboard names in the rive file
    /// - Returns a list of artboard names
    open func artboardNames() -> [String] {
        if let names = riveFile?.artboardNames() {
            return names
        } else {
            return []
        }
    }
    
    /// Returns a list of animation names for the active artboard
    /// - Returns a list of animation names
    open func animationNames() -> [String] {
        if let names = _artboard?.animationNames() {
            return names
        } else {
            return []
        }
    }
    
    /// Returns a list of state machine names for the active artboard
    /// - Returns a list of state machine names
    open func stateMachineNames() -> [String] {
        if let names = _artboard?.stateMachineNames() {
            return names
        } else {
            return []
        }
    }
    
    /// Returns true if the active artboard has the specified name
    /// - Parameter name: the artboard name to check
    open func isArtboard(name: String) -> Bool {
        return _artboard?.name() == name
    }
    
    /// Returns a list of valid state machine inputs for any instanced state machine
    /// - Returns a list of valid state machine inputs and their types
    open func stateMachineInputs() throws -> [StateMachineInput] {
        var inputs: [StateMachineInput] = []
        try stateMachines.forEach({ machine in
            let inputCount = machine.inputCount()
            for i in 0..<inputCount {
                let input = try machine.input(from: i)
                var type = StateMachineInputType.boolean
                if input.isTrigger() { type = StateMachineInputType.trigger }
                else if input.isNumber() { type = StateMachineInputType.number }
                inputs.append(StateMachineInput(name: input.name(), type: type))
            }
        });
        return inputs
    }
    
    
    /// WIP to test animation behaviour when its canvas moves to the background
    @objc func animationWillMoveToBackground() {
        print("Triggers when app is moving to background")
    }
    
    /// WIP to test animation behaviour when its canvas moves to the foreground
    @objc func animationWillEnterForeground() {
        print("Triggers when app is moving to foreground")
    }
}

// MARK:- Animation Loop
extension RiveView {
    /// Are any Animations or State Machines playing.
    open var isPlaying: Bool {
        get {
            return !playingAnimations.isEmpty || !playingStateMachines.isEmpty
        }
    }
    
    /// Creates a Rive renderer and applies the currently animating artboard to it
    /// - Parameter rect: the `GCRect` that we will fit the artboard into.
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self._artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: alignment, with: fit)
        artboard.draw(renderer)
    }
    

    // Starts the animation timer
    private func runTimer() {
        if displayLinkProxy == nil {
            displayLinkProxy = CADisplayLinkProxy(
                handle: { [weak self] in
                    self?.tick()
                }, to: .main, forMode: .common)
        }
        if displayLinkProxy?.displayLink?.isPaused == true {
            displayLinkProxy?.displayLink?.isPaused = false
        }
    }
    
    // Stops the animation timer
    private func stopTimer() {
        displayLinkProxy?.invalidate()
        displayLinkProxy = nil
        lastTime = 0
    }
    
    /// Start a redraw:
    /// - determine the elapsed time
    /// - advance the artbaord, which will invalidate the display.
    /// - if the artboard has come to a stop, stop.
    @objc func tick() {
        guard let displayLink = displayLinkProxy?.displayLink else {
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
        if(!isPlaying) {
            stopTimer()
        }
    }
    
    /// Advance all playing animations by a set amount.
    ///
    /// This will also trigger any events for configured delegates.
    /// - Parameter delta: elapsed seconds.
    open func advance(delta:Double) {
        guard let artboard = _artboard else {
            return
        }
        
        // Testing firing events here
        eventQueue.fireAll()
        
        animations.forEach{ animation in
            if playingAnimations.contains(animation) {
                let stillPlaying = animation.advance(by: delta)
                animation.apply(to: artboard)
                if !stillPlaying {
                    _stop(animation)
                } else {
                    
                    // Check if the animation looped and if so, call the delegate
                    if animation.didLoop() {
                        loopDelegate?.loop(animation.name(), type: Int(animation.loop()))
                    }
                }
            }
        }
        stateMachines.forEach{ stateMachine in
            if playingStateMachines.contains(stateMachine) {
                let stillPlaying = stateMachine.advance(artboard, by: delta)
                
                
                stateMachine.stateChanges().forEach{
                    stateChangeName in stateChangeDelegate?.stateChange(stateMachine.name(), stateChangeName)}
                
                if !stillPlaying {
                    _pause(stateMachine)
                }
            }
        }
        // advance the artboard
        artboard.advance(by: delta)
        // Trigger a redraw
        self.setNeedsDisplay()
    }
}

// MARK:- Control Animations
extension RiveView {
    
    /// Reset the rive view & reload any provided `riveFile`
    public func reset(artboard: String? = nil, animation: String? = nil, stateMachine: String? = nil) throws {
        stopTimer()
        if let riveFile = self.riveFile {
            // Calling configure will create a new artboard instance, reseting the animation
            try configure(riveFile,
                      andArtboard: artboard,
                      andAnimation: animation,
                      andStateMachine: stateMachine,
                      andAutoPlay: autoPlay)
        }
    }
    
    
    /// Play the first animation of the loaded artboard
    /// - Parameters:
    ///   - loop: provide a `Loop` to overwrite the loop mode used to play the animation.
    ///   - direction: provide a `Direction` to overwrite the direction that the animation plays in.
    public func play(
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto
    ) throws {
        guard let guardedArtboard=_artboard else {
            return;
        }
        
        try _playAnimation(
            animationName:guardedArtboard.firstAnimation().name(),
            loop:loop,
            direction:direction
        )
        runTimer()
    }
    
    /// Plays the specified animation or state machine with optional loop and directions
    /// - Parameters:
    ///   - animationName: name of the animation to play
    ///   - loop: overrides the animation's loop setting
    ///   - direction: overrides the animation's default direction (forwards)
    ///   - isStateMachine: true of the name refers to a state machine and not an animation
    public func play(
        animationName: String,
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try _playAnimation(
            animationName:animationName,
            loop:loop,
            direction:direction,
            isStateMachine:isStateMachine
        )
        runTimer()
    }
    
    /// Plays the list of animations or state machines with optional loop and directions
    /// - Parameters:
    ///   - animationNames: list of names of the animations to play
    ///   - loop: overrides the animation's loop setting
    ///   - direction: overrides the animation's default direction (forwards)
    ///   - isStateMachine: true of the name refers to a state machine and not an animation
    public func play(
        animationNames:[String],
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try animationNames.forEach{ animationName in
           try _playAnimation(
                animationName:animationName,
                loop:loop,
                direction:direction,
                isStateMachine:isStateMachine
            )
        }
        
        runTimer()
    }
    
    
    /// Pauses all playing animations and state machines
    public func pause() {
        playingAnimations.forEach { animation in _pause(animation) }
        playingStateMachines.forEach { stateMachine in _pause(stateMachine) }
    }
    
    /// Pause a specific animation or statemachine.
    /// - Parameters:
    ///   - animationName: the name of the animation or state machine to pause.
    ///   - isStateMachine: a flag to signify if the animation is a state machine.
    public func pause(animationName:String, isStateMachine:Bool=false) {
        if (isStateMachine){
            _stateMachines(animationName: animationName).forEach{ animation in _pause(animation)}
        } else {
            _animations(animationName: animationName).forEach{ animation in _pause(animation)}
        }
    }
    
    /// Pause all matching animations or statemachines.
    /// - Parameters:
    ///   - animationNames: the names of the animation or state machine to pause.
    ///   - isStateMachine: a flag to signify if the animations are state machines.
    public func pause(animationNames:[String], isStateMachine:Bool=false) {
        if (isStateMachine){
            _stateMachines(animationNames: animationNames).forEach{ animation in _pause(animation)}
        } else {
            _animations(animationNames: animationNames).forEach{ animation in _pause(animation)}
        }
    }
    
    /// Stops all playing animations and state machines
    ///
    /// Stopping will remove the animation instance, as well as pausing the animation, restarting the
    /// animation will start from the beginning
    public func stop() {
        animations.forEach { animation in _stop(animation) }
        stateMachines.forEach { stateMachine in _stop(stateMachine) }
    }
    
    /// Stops a specific animation or statemachine.
    /// - Parameters:
    ///   - animationName: the name of the animation or state machine to stop.
    ///   - isStateMachine: a flag to signify if the animation is a state machine.
    public func stop(animationName:String, isStateMachine:Bool=false) {
        if (isStateMachine){
            _stateMachines(animationName: animationName).forEach{ animation in _stop(animation)}
        } else {
            _animations(animationName: animationName).forEach{ animation in _stop(animation)}
        }
    }
    
    /// Stops all matching animations or statemachines.
    /// - Parameters:
    ///   - animationNames: the names of the animation or state machine to stop.
    ///   - isStateMachine: a flag to signify if the animations are state machines.
    public func stop(animationNames:[String], isStateMachine:Bool=false) {
        if (isStateMachine){
            _stateMachines(animationNames: animationNames).forEach{ animation in _stop(animation)}
        } else {
            _animations(animationNames: animationNames).forEach{ animation in _stop(animation)}
        }
    }
    
    
    /// `fire` a state machien `Trigger` input on a specific state machine.
    ///
    /// The state machine will be played as a side effect of this.
    /// - Parameters:
    ///   - stateMachineName: the state machine that this input belongs to
    ///   - inputName: the name of the `Trigger` input
    open func fireState(_ stateMachineName: String, inputName: String) throws {
        let stateMachineInstances = try _getOrCreateStateMachines(animationName: stateMachineName)
        try stateMachineInstances.forEach { stateMachine in
            stateMachine.getTrigger(inputName).fire()
            try _play(stateMachine)
        }
        runTimer()
    }
    
    /// Update a state machines `Boolean` input state to true or false.
    ///
    /// The state machine will be played as a side effect of this.
    /// - Parameters:
    ///   - stateMachineName: the state machine that this input belongs to
    ///   - inputName: the name of the `Boolean` input
    ///   - value: true or false
    open func setBooleanState(_ stateMachineName: String, inputName: String, value: Bool) throws {
        let stateMachineInstances = try _getOrCreateStateMachines(animationName: stateMachineName)
        try stateMachineInstances.forEach { stateMachine in
            stateMachine.getBool(inputName).setValue(value)
            try _play(stateMachine)
        }
        runTimer()
    }
    
    /// Update a state machines `Number` input state to true or false.
    ///
    /// The state machine will be played as a side effect of this.
    /// - Parameters:
    ///   - stateMachineName: the state machine that this input belongs to
    ///   - inputName: the name of the `Number` input
    ///   - value: the new value for the state to hold
    open func setNumberState(_ stateMachineName: String, inputName: String, value: Float) throws {
        let stateMachineInstances = try _getOrCreateStateMachines(animationName: stateMachineName)
        try stateMachineInstances.forEach { stateMachine in
            stateMachine.getNumber(inputName).setValue(value)
            try _play(stateMachine)
        }
        runTimer()
    }
    
    private func _getOrCreateStateMachines(
        animationName: String
    ) throws -> [RiveStateMachineInstance]{
        let stateMachineInstances = _stateMachines(animationName: animationName)
        if (stateMachineInstances.isEmpty){
            guard let guardedArtboard=_artboard else {
                return []
            }
            let stateMachineInstance = try guardedArtboard.stateMachine(fromName: animationName).instance()
            return [stateMachineInstance]
        }
        return stateMachineInstances
    }
    
    private func _getOrCreateLinearAnimationInstances(
        animationName: String
    ) throws -> [RiveLinearAnimationInstance] {
        let animationInstances = _animations(animationName: animationName)
        
        if (animationInstances.isEmpty){
            guard let guardedArtboard=_artboard else {
                return []
            }
            let animationInstance = try guardedArtboard.animation(fromName:animationName).instance()
            return [animationInstance]
        }
        return animationInstances
    }
    
    private func _playAnimation(
        animationName: String,
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        if (isStateMachine) {
            let stateMachineInstances = try _getOrCreateStateMachines(animationName:animationName)
            try stateMachineInstances.forEach { stateMachineInstance in
                try _play(stateMachineInstance)
            }
        } else {
            let animationInstances = try _getOrCreateLinearAnimationInstances(animationName: animationName)
            
            animationInstances.forEach { animationInstance in
                _play(
                    animation:animationInstance,
                    loop:loop, direction:direction
                )
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
        if (loop != .loopAuto) {
            animationInstance.loop(Int32(loop.rawValue))
        }
        if (!animations.contains(animationInstance)) {
            if (direction == .directionBackwards) {
                animationInstance.setTime(animationInstance.animation().endTime())
            }
            animations.append(
                animationInstance
            )
        }
        if (direction == .directionForwards) {
            animationInstance.direction(1)
        }else if (direction == .directionBackwards) {
            animationInstance.direction(-1)
        }
        
        playingAnimations.insert(animationInstance)
        eventQueue.add( { self.playDelegate?.play(animationInstance.name(), isStateMachine:false) } )
    }
    
    private func _pause(_ animation: RiveLinearAnimationInstance) {
        let removed = playingAnimations.remove(animation)
        if removed != nil {
            eventQueue.add( { self.pauseDelegate?.pause(animation.name(), isStateMachine:false) } )
        }
    }
    
    /// Stops an animation
    ///
    /// - Parameter animation: the animation to pause
    private func _stop(_ animation: RiveLinearAnimationInstance) {
        let initialCount = animations.count
        // TODO: Better way to do this?
        animations = animations.filter { $0 != animation }
        playingAnimations.remove(animation)
        if (initialCount != animations.count) {
            // eventQueue.add( { self.stopDelegate?.stop(animation.name()) } )
            // Firing this immediately as if it's the only animation stopping, advance won't get called
            self.stopDelegate?.stop(animation.name(), isStateMachine:false)
        }
    }
    
    private func _play(_ stateMachineInstance: RiveStateMachineInstance) throws {
        if (!stateMachines.contains(stateMachineInstance)) {
            stateMachines.append(
                stateMachineInstance
            )
        }
        
        playingStateMachines.insert(stateMachineInstance)
        eventQueue.add( { self.playDelegate?.play(stateMachineInstance.name(),isStateMachine:true) } )
        let inputs = try self.stateMachineInputs()
        eventQueue.add( { self.inputsDelegate?.inputs(inputs) } )
    }
    
    /// Pauses a playing state machine
    ///
    /// - Parameter stateMachine: the state machine to pause
    private func _pause(_ stateMachine: RiveStateMachineInstance) {
        let removed = playingStateMachines.remove(stateMachine)
        if removed != nil {
            eventQueue.add( { self.pauseDelegate?.pause(stateMachine.name(),isStateMachine:true) } )
        }
    }
    
    /// Stops an animation
    ///
    /// - Parameter animation: the animation to pause
    private func _stop(_ stateMachine: RiveStateMachineInstance) {
        let initialCount = stateMachines.count
        // TODO: Better way to do this?
        stateMachines = stateMachines.filter{ it in
            return it != stateMachine
        }
        playingStateMachines.remove(stateMachine)
        if (initialCount != stateMachines.count){
            eventQueue.add( { self.stopDelegate?.stop(stateMachine.name(),isStateMachine:true) } )
        }
    }
}
