//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/23/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

public protocol RivePlayerDelegate: AnyObject {
    func loop(animation animationName: String, type: Int)
    func play(animation animationName: String, isStateMachine: Bool)
    func pause(animation animationName: String, isStateMachine: Bool)
    func stop(animation animationName: String, isStateMachine: Bool)
}

@objc public protocol RiveTouchDelegate: AnyObject {
    @objc optional func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
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

/// Delegate for reporting changes to available input states
public protocol RInputDelegate: AnyObject {
    func inputs(_ inputs: [StateMachineInput])
}
/// signature for inputs action delegate function
public typealias InputsAction = (([StateMachineInput]) -> Void)?

/// Delegate for new input states
public protocol RStateDelegate: AnyObject {
    func stateChange(_ stateMachineName: String, _ stateName: String)
}
/// signature for state change action delegate function
public typealias StateChangeAction = ((String, String) -> Void)?

/// Stores config options for a RiveFile when rive files load async
struct ConfigOptions {
    let riveFile: RiveFile
    var artboardName: String? = nil
    var animationName: String? = nil
    var stateMachineName: String?
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

// Tracks a queue of events that haven't been fired yet. We do this so
// that we're not calling delegates and modifying state while a view is
// updating (e.g. being initialized, as we autoplay and fire play events
// during the view's init otherwise
class EventQueue {
    var events: [() -> Void] = []

    func add(_ event: @escaping () -> Void) {
        events.append(event)
    }

    func fireAll() {
        events.forEach { $0() }
        events.removeAll()
    }
}

open class RiveView: RiveRendererView {
    // Configuration
    private var riveFile: RiveFile?
    private var autoPlay: Bool = true
    open var artboard: RiveArtboard?
    open var fit: Fit = .fitContain {
        didSet { artboard?.advance(by: 0) }
    }
    open var alignment: Alignment = .alignmentCenter {
        didSet { artboard?.advance(by: 0) }
    }
    
    // Playback controls
    public var animations: [RiveLinearAnimationInstance] = []
    public var playingAnimations: Set<RiveLinearAnimationInstance> = []
    public var stateMachines: [RiveStateMachineInstance] = []
    public var playingStateMachines: Set<RiveStateMachineInstance> = []
    
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: CADisplayLinkProxy?
    
    // Delegates
    public weak var playerDelegate: RivePlayerDelegate?
    public weak var touchDelegate: RiveTouchDelegate?
    public weak var inputsDelegate: RInputDelegate?
    public weak var stateChangeDelegate: RStateDelegate?
    
    // Tracks config options when rive files load asynchronously
    internal var configOptions: ConfigOptions?
    
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
    ///   - playerDelegate: to get callbacks when an `Animation` changes state
    ///   - inputsDelegate: to get callbacks for inputs relevant to a loaded `StateMachine`.
    ///   - stateChangeDelegate: to get callbacks for when the current state of a StateMachine chagnes.
    public init(
        riveFile: RiveFile,
        fit: Fit = .fitContain,
        alignment: Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil,
        stateMachineName: String? = nil,
        playerDelegate: RivePlayerDelegate? = nil,
        inputsDelegate: RInputDelegate? = nil,
        stateChangeDelegate: RStateDelegate? = nil
    ) throws {
        super.init(frame: .zero)
        self.fit = fit
        self.alignment = alignment
        self.playerDelegate = playerDelegate
        self.inputsDelegate = inputsDelegate
        self.stateChangeDelegate = stateChangeDelegate
        
        try configure(riveFile, artboardName: artboardName, animationName: animationName, stateMachineName: stateMachineName, autoPlay: autoplay)
    }
    
    /// Constructor with a .riv file name.
    /// - Parameters:
    ///   - resource: the resource to load the rive file from
    ///   - fit: to specify how and if the animation should be resized to fit its container.
    ///   - alignment: to specify how the animation should be aligned to its container.
    ///   - autoplay: play as soon as the animaiton is loaded.
    ///   - artboard: determine the `Artboard`to use, by default the first Artboard in the riveFile is picked.
    ///   - animation: determine the `Animation`to play, by default the first Animation/StateMachine in the riveFile is picked.
    ///   - stateMachine: determine the `StateMachine`to play, ignored if `animation` is set. By default the first Animation/StateMachine in the riveFile is picked.
    ///   - playerDelegate: to get callbacks when an `Animation` changes state
    ///   - inputsDelegate: to get callbacks for inputs relevant to a loaded `StateMachine`.
    ///   - stateChangeDelegate: to get callbacks for when the current state of a StateMachine chagnes.
    public init(
        fileName: String,
        fit: Fit = .fitContain,
        alignment: Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil,
        stateMachineName: String? = nil,
        playerDelegate: RivePlayerDelegate? = nil,
        inputsDelegate: RInputDelegate? = nil,
        stateChangeDelegate: RStateDelegate? = nil
    ) throws {
        super.init(frame: .zero)
        let riveFile = try RiveFile(name: fileName)
        self.fit = fit
        self.alignment = alignment
        self.playerDelegate = playerDelegate
        self.inputsDelegate = inputsDelegate
        self.stateChangeDelegate = stateChangeDelegate
        
        try configure(riveFile, artboardName: artboardName, animationName: animationName, stateMachineName: stateMachineName, autoPlay: autoplay)
    }
    
    /// Constructor with a resource file.
    /// - Parameters:
    ///   - httpUrl: the url to load the file from
    ///   - fit: to specify how and if the animation should be resized to fit its container.
    ///   - alignment: to specify how the animation should be aligned to its container.
    ///   - autoplay: play as soon as the animaiton is loaded.
    ///   - artboard: determine the `Artboard`to use, by default the first Artboard in the riveFile is picked.
    ///   - animation: determine the `Animation`to play, by default the first Animation/StateMachine in the riveFile is picked.
    ///   - stateMachine: determine the `StateMachine`to play, ignored if `animation` is set. By default the first Animation/StateMachine in the riveFile is picked.
    ///   - playerDelegate: to get callbacks when an `Animation` changes state
    ///   - inputsDelegate: to get callbacks for inputs relevant to a loaded `StateMachine`.
    ///   - stateChangeDelegate: to get callbacks for when the current state of a StateMachine chagnes.
    public init(
        webURL: String,
        fit: Fit = .fitContain,
        alignment: Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil,
        stateMachineName: String? = nil,
        playerDelegate: RivePlayerDelegate? = nil,
        inputsDelegate: RInputDelegate? = nil,
        stateChangeDelegate: RStateDelegate? = nil
    ) throws {
        super.init(frame: .zero)
        let riveFile = RiveFile(httpUrl: webURL, with:self)!
        self.fit = fit
        self.alignment = alignment
        self.playerDelegate = playerDelegate
        self.inputsDelegate = inputsDelegate
        self.stateChangeDelegate = stateChangeDelegate
        
        try configure(riveFile, artboardName: artboardName, animationName: animationName, stateMachineName: stateMachineName, autoPlay: autoplay)
    }
    
    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        super.init(frame: .zero)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - Asynchronously load file
extension RiveView: RiveFileDelegate {
    public func riveFileDidLoad(_ riveFile: RiveFile) throws {
        try self.configure(riveFile)
    }
}

// MARK: - Configure
extension RiveView {
    
    // Refactor:
    // 1. Make a buffer of config settings
    // - Config settings should be buffered in the RiveModel
    // 2. Check that the file is loaded
    // - RiveFile should be stored in the RiveModel
    // 3. Make a new root Artboard using riveFile and artboardName
    // - The instance of the artboard should be communicated to the RiveView by the RiveViewModel
    // 4. Store instance of the new artboard
    // 5. If autoplay=true play animation, else advance(0)
    // - The RiveModel should communicate that it's done configuring, which should trigger the RiveViewModel to tell the RiveView to play or advance(0)
    /// Updates the artboard and layout options
    open func configure(
        _ riveFile: RiveFile,
        artboardName: String? = nil,
        animationName: String? = nil,
        stateMachineName: String? = nil,
        autoPlay: Bool = true
    ) throws {
        // If it isn't loaded, early out
        guard riveFile.isLoaded else { return }
        
        // Testing stuff
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(animationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(animationWillMoveToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Ensure the view's transparent
        self.isOpaque = false
        self.riveFile = riveFile
        
        try refresh(artboardName: artboardName, animationName: animationName, stateMachineName: stateMachineName, autoPlay: autoPlay)
    }
    
    open func refresh(withViewModel viewModel: RiveViewModel) throws {
        stop()
        playingAnimations.removeAll()
        playingStateMachines.removeAll()
        animations.removeAll()
        stateMachines.removeAll()
        stopTimer()
        
        // Always save the config options to preserve for reset
        configOptions = ConfigOptions(
            riveFile: self.riveFile!,
            artboardName: viewModel.artboardName ?? configOptions?.artboardName,
            animationName: viewModel.animationName ?? configOptions?.animationName,
            stateMachineName: viewModel.stateMachineName ?? configOptions?.stateMachineName,
            autoPlay: viewModel.autoplay  // has a default setting
        )
        
        self.autoPlay = configOptions!.autoPlay
        
        try setArtboard(withName: configOptions?.artboardName, inFile: riveFile)
        
        // Start the animation loop
        if autoPlay {
            if let animationName = configOptions?.animationName {
                try play(animationName: animationName)
            } else if let stateMachineName = configOptions?.stateMachineName {
                try play(animationName: stateMachineName, isStateMachine: true)
            } else {
                try play()
            }
        } else {
            advance(delta: 0)
        }
    }
    
    /// Stops the current animation and refreshes the view with the new data
    open func refresh(artboardName: String? = nil, animationName: String? = nil, stateMachineName: String? = nil, autoPlay: Bool? = nil) throws {
        let viewModel = RiveViewModel(
            fileName: "",
            stateMachineName: stateMachineName,
            autoplay: autoPlay ?? self.autoPlay,
            artboardName: artboardName,
            animationName: animationName
        )
        try refresh(withViewModel: viewModel)
    }
    
    /// Reset the rive view & reload any provided `riveFile`
    public func reset(artboard: String? = nil, animation: String? = nil, stateMachine: String? = nil) throws {
        stopTimer()
        if let riveFile = self.riveFile {
            // Calling configure will create a new artboard instance, reseting the animation
            try configure(riveFile, artboardName: artboard, animationName: animation, stateMachineName: stateMachine, autoPlay: autoPlay)
        }
    }
    
    func setArtboard(withName artboardName: String?, inFile riveFile: RiveFile?) throws {
        let rootArtboard: RiveArtboard?
        
        if let artboardName = artboardName {
            rootArtboard = try riveFile?.artboard(fromName: artboardName)
        } else {
            rootArtboard = try riveFile?.artboard()
        }
        
        guard let artboard = rootArtboard else {
            fatalError("No default artboard exists")
        }
        
        if artboard.animationCount() == 0 {
            fatalError("No animations in the file.")
        }
        
        self.artboard = artboard
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
        if let names = artboard?.animationNames() {
            return names
        } else {
            return []
        }
    }
    
    /// Returns a list of state machine names for the active artboard
    /// - Returns a list of state machine names
    open func stateMachineNames() -> [String] {
        if let names = artboard?.stateMachineNames() {
            return names
        } else {
            return []
        }
    }
    
    /// Returns true if the active artboard has the specified name
    /// - Parameter artboard: the artboard name to check
    open func isActive(artboard: String) -> Bool {
        return self.artboard?.name() == artboard
    }
    
    /// Returns a list of valid state machine inputs for any instanced state machine
    /// - Returns a list of valid state machine inputs and their types
    open func stateMachineInputs() throws -> [StateMachineInput] {
        var inputs: [StateMachineInput] = []
        
        for machine in stateMachines {
            let inputCount = machine.inputCount()
            for i in 0 ..< inputCount {
                let input = try machine.input(from: i)
                var type: StateMachineInputType = .boolean
                if input.isTrigger() {
                    type = .trigger
                } else if input.isNumber() {
                    type = .number
                }
                inputs.append(StateMachineInput(name: input.name(), type: type))
            }
        }
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

// MARK: - Animation Loop
extension RiveView {
    /// Are any Animations or State Machines playing.
    open var isPlaying: Bool {
        return !playingAnimations.isEmpty || !playingStateMachines.isEmpty
    }
    
    override public func isPaused() -> Bool {
        return !isPlaying
    }
    
// TODO: Zach - DrawRive is a critical part of RiveView
    // Components that it needs:
    // - an ArtboardInstance
    // - .align()
    override public func drawRive(_ rect: CGRect, size: CGSize) {
        guard let artboard = artboard else { return }
        let alignmentRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: size.width, height: size.height)
        
        align(with: alignmentRect, contentRect: artboard.bounds(), alignment: alignment, fit: fit)
        draw(with: artboard)
    }
    
    // Starts the animation timer
    private func runTimer() {
        if displayLinkProxy == nil {
            displayLinkProxy = CADisplayLinkProxy(
                handle: { [weak self] in
                    self?.tick()
                },
                to: .main,
                forMode: .common
            )
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
    
    
// TODO: Zach - Tick is a critical part of RiveView
    // Components it needs:
    // - displayLinkProxy
    // - .advance()
    // - .stopTimer()
    // - isPlaying
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
        let elapsedTime = timestamp - lastTime
        lastTime = timestamp
        advance(delta: elapsedTime)
        if !isPlaying {
            stopTimer()
        }
    }
    
// TODO: Zach - Critical part of RiveView
    // - ArtboardInstance
    // - eventQueue
    // - total AnimationInstance array
    // - playing AnimationInstance set
    // - PlayerDelegate
    // - total AnimationInstance array
    // - playing AnimationInstance set
    // - StateChangeDelegate
    /// Advance all playing animations by a set amount.
    ///
    /// This will also trigger any events for configured delegates.
    /// - Parameter delta: elapsed seconds.
    open func advance(delta: Double) {
        guard let artboard = artboard else { return }
        
        // Testing firing events here
        eventQueue.fireAll()
        
        for animation in animations where playingAnimations.contains(animation) {
            let stillPlaying = animation.advance(by: delta)
            animation.apply()
            
            if !stillPlaying {
                _stop(animation)
            } else {
                // Check if the animation looped and if so, call the delegate
                if animation.didLoop() {
                    playerDelegate?.loop(animation: animation.name(), type: Int(animation.loop()))
                }
            }
        }
        
        for stateMachine in stateMachines where playingStateMachines.contains(stateMachine) {
            let stillPlaying = stateMachine.advance(by: delta)
            
            stateMachine.stateChanges().forEach { stateChangeDelegate?.stateChange(stateMachine.name(), $0) }
            
            if !stillPlaying {
                _pause(stateMachine)
            }
        }
        
        // advance the artboard
        artboard.advance(by: delta)
        // Trigger a redraw
        self.setNeedsDisplay()
    }
}

// MARK: - Control Animations
extension RiveView {
    
    /// Plays the first animation of the loaded artboard
    /// - Parameters:
    ///   - loop: provide a `Loop` to overwrite the loop mode used to play the animation.
    ///   - direction: provide a `Direction` to overwrite the direction that the animation plays in.
    public func play(loop: Loop = .loopAuto, direction: Direction = .directionAuto) throws {
        guard let guardedArtboard = artboard else { return }
        
        try _playAnimation(animationName: guardedArtboard.firstAnimation().name(), loop: loop, direction: direction)
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
        try _playAnimation(animationName: animationName, loop: loop, direction: direction, isStateMachine: isStateMachine)
        runTimer()
    }
    
    /// Plays the list of animations or state machines with optional loop and directions
    /// - Parameters:
    ///   - animationNames: list of names of the animations to play
    ///   - loop: overrides the animation's loop setting
    ///   - direction: overrides the animation's default direction (forwards)
    ///   - isStateMachine: true of the name refers to a state machine and not an animation
    public func play(
        animationNames: [String],
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        for animationName in animationNames {
            try _playAnimation(
                animationName: animationName,
                loop: loop,
                direction: direction,
                isStateMachine: isStateMachine
            )
        }
        
        runTimer()
    }
    
    /// Pauses all playing animations and state machines
    public func pause() {
        playingAnimations.forEach { _pause($0) }
        playingStateMachines.forEach { _pause($0) }
    }
    
    /// Pause a specific animation or statemachine.
    /// - Parameters:
    ///   - animationName: the name of the animation or state machine to pause.
    ///   - isStateMachine: a flag to signify if the animation is a state machine.
    public func pause(animationName: String, isStateMachine: Bool = false) {
        if isStateMachine {
            _stateMachines(withAnimationName: animationName).forEach { _pause($0) }
        } else {
            _animations(withName: animationName).forEach { _pause($0) }
        }
    }
    
    /// Pause all matching animations or statemachines.
    /// - Parameters:
    ///   - animationNames: the names of the animation or state machine to pause.
    ///   - isStateMachine: a flag to signify if the animations are state machines.
    public func pause(animationNames: [String], isStateMachine: Bool = false) {
        if isStateMachine {
            _stateMachines(withAnimationNames: animationNames).forEach { _pause($0) }
        } else {
            _animations(withNames: animationNames).forEach { _pause($0) }
        }
    }
    
    /// Stops all playing animations and state machines
    ///
    /// Stopping will remove the animation instance, as well as pausing the animation, restarting the
    /// animation will start from the beginning
    public func stop() {
        animations.forEach { _stop($0) }
        stateMachines.forEach { _stop($0) }
    }
    
    /// Stops a specific animation or statemachine.
    /// - Parameters:
    ///   - animationName: the name of the animation or state machine to stop.
    ///   - isStateMachine: a flag to signify if the animation is a state machine.
    public func stop(animationName: String, isStateMachine: Bool = false) {
        if isStateMachine {
            _stateMachines(withAnimationName: animationName).forEach { _stop($0) }
        } else {
            _animations(withName: animationName).forEach { _stop($0) }
        }
    }
    
    /// Stops all matching animations or statemachines.
    /// - Parameters:
    ///   - animationNames: the names of the animation or state machine to stop.
    ///   - isStateMachine: a flag to signify if the animations are state machines.
    public func stop(animationNames: [String], isStateMachine: Bool = false) {
        if isStateMachine {
            _stateMachines(withAnimationNames: animationNames).forEach { _stop($0) }
        } else {
            _animations(withNames: animationNames).forEach { _stop($0) }
        }
    }
    
    /// `fire` a state machine `Trigger` input on a specific state machine.
    ///
    /// The state machine will be played as a side effect of this.
    /// - Parameters:
    ///   - stateMachineName: the state machine that this input belongs to
    ///   - inputName: the name of the `Trigger` input
    open func fireState(_ stateMachineName: String, inputName: String) throws {
        let stateMachineInstances = try _getOrCreateStateMachines(animationName: stateMachineName)
        for stateMachine in stateMachineInstances {
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
    
    private func _getOrCreateStateMachines(animationName: String) throws -> [RiveStateMachineInstance] {
        let stateMachineInstances = _stateMachines(withAnimationName: animationName)
        if stateMachineInstances.isEmpty {
            guard let guardedArtboard = artboard else { return [] }
            
            let stateMachineInstance = try guardedArtboard.stateMachine(fromName: animationName).instance(with: guardedArtboard)
            return [stateMachineInstance]
        }
        return stateMachineInstances
    }
    
    private func _getOrCreateLinearAnimationInstances(animationName: String) throws -> [RiveLinearAnimationInstance] {
        let animationInstances = _animations(withName: animationName)
        
        if animationInstances.isEmpty {
            guard let guardedArtboard = artboard else { return [] }
            
            let animationInstance = try guardedArtboard.animation(fromName: animationName).instance(with: guardedArtboard)
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
        if isStateMachine {
            let stateMachineInstances = try _getOrCreateStateMachines(animationName: animationName)
            try stateMachineInstances.forEach { try _play($0) }
        } else {
            let animationInstances = try _getOrCreateLinearAnimationInstances(animationName: animationName)
            animationInstances.forEach { _play(animation: $0, loop: loop, direction: direction) }
        }
    }
    
    private func _animations(withName animationName: String) -> [RiveLinearAnimationInstance] {
        return _animations(withNames: [animationName])
    }
    
    private func _animations(withNames animationNames: [String]) -> [RiveLinearAnimationInstance] {
        return animations.filter { animationNames.contains($0.animation().name()) }
    }
    
    private func _stateMachines(withAnimationName animationName: String) -> [RiveStateMachineInstance] {
        return _stateMachines(withAnimationNames: [animationName])
    }
    
    private func _stateMachines(withAnimationNames animationNames: [String]) -> [RiveStateMachineInstance] {
        return stateMachines.filter { animationNames.contains($0.stateMachine().name()) }
    }
    
    private func _play(animation: RiveLinearAnimationInstance, loop: Loop, direction: Direction) {
        if loop != .loopAuto {
            animation.loop(Int32(loop.rawValue))
        }
        if !animations.contains(animation) {
            if direction == .directionBackwards {
                animation.setTime(animation.animation().endTime())
            }
            animations.append(animation)
        }
        if direction == .directionForwards {
            animation.direction(1)
        } else if direction == .directionBackwards {
            animation.direction(-1)
        }
        
        playingAnimations.insert(animation)
        eventQueue.add { self.playerDelegate?.play(animation: animation.name(), isStateMachine: false) }
    }
    
    private func _pause(_ animation: RiveLinearAnimationInstance) {
        if let removed = playingAnimations.remove(animation) {
            eventQueue.add { self.playerDelegate?.pause(animation: removed.name(), isStateMachine: false) }
        }
    }
    
    /// Stops an animation
    ///
    /// - Parameter animation: the animation to pause
    private func _stop(_ animation: RiveLinearAnimationInstance) {
        let initialCount = animations.count
        animations.removeAll { $0 == animation }
        playingAnimations.remove(animation)
        
        if initialCount != animations.count {
            // Firing this immediately as if it's the only animation stopping, advance won't get called
            self.playerDelegate?.stop(animation: animation.name(), isStateMachine: false)
        }
    }
    
    private func _play(_ stateMachineInstance: RiveStateMachineInstance) throws {
        if !stateMachines.contains(stateMachineInstance) {
            stateMachines.append(stateMachineInstance)
        }
        
        playingStateMachines.insert(stateMachineInstance)
        eventQueue.add { self.playerDelegate?.play(animation: stateMachineInstance.name(), isStateMachine: true) }
        let inputs = try self.stateMachineInputs()
        eventQueue.add { self.inputsDelegate?.inputs(inputs) }
    }
    
    /// Pauses a playing state machine
    ///
    /// - Parameter stateMachine: the state machine to pause
    private func _pause(_ stateMachine: RiveStateMachineInstance) {
        let removed = playingStateMachines.remove(stateMachine)
        if removed != nil {
            eventQueue.add { self.playerDelegate?.pause(animation: stateMachine.name(), isStateMachine: true) }
        }
    }
    
    /// Stops an animation
    ///
    /// - Parameter animation: the animation to pause
    private func _stop(_ stateMachine: RiveStateMachineInstance) {
        let initialCount = stateMachines.count
        stateMachines.removeAll { $0 == stateMachine }
        playingStateMachines.remove(stateMachine)
        
        if initialCount != stateMachines.count {
            eventQueue.add { self.playerDelegate?.stop(animation: stateMachine.name(), isStateMachine: true) }
        }
    }
}

// MARK: - Artboard Events
extension RiveView: RArtboardDelegate {
    // MARK: RArtboardDelegate
    
    /// NOTE: This is not yet in use
    /// Events triggered in the RiveArtboard by user input
    public func artboard(_ artboard: RiveArtboard, didTriggerEvent event: String) {
        // Touch events generated by the hit detection in rive-cpp are given to the artboard
    }
    
    // MARK: UIResponder
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        artboard?.touched(at: location, info: 0)
        touchDelegate?.touchBegan?(onArtboard: artboard, atLocation: location)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        artboard?.touched(at: location, info: 0)
        touchDelegate?.touchMoved?(onArtboard: artboard, atLocation: location)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        artboard?.touched(at: location, info: 0)
        touchDelegate?.touchEnded?(onArtboard: artboard, atLocation: location)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        artboard?.touched(at: location, info: 0)
        touchDelegate?.touchCancelled?(onArtboard: artboard, atLocation: location)
    }
}
