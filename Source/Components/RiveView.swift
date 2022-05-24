//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/23/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation


open class RiveView: RiveRendererView {
    // MARK: Configuration
    internal weak var riveModel: RiveModel!
    internal var fit: RiveRuntime.Fit = .fitContain { didSet { setNeedsDisplay() } }
    internal var alignment: RiveRuntime.Alignment = .alignmentCenter { didSet { setNeedsDisplay() } }
    
    // MARK: Render Loop
    internal private(set) var isPlaying: Bool = false
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: CADisplayLinkProxy?
    private var eventQueue = EventQueue()
    
    // MARK: Delegates
    public var playerDelegate: RivePlayerDelegate?
    public var stateMachineDelegate: RiveStateMachineDelegate?
    
    // MARK: Debug
    private var fpsCounter: FPSCounterView? = nil
    public var showFPS: Bool = false {
        didSet {
            if showFPS && fpsCounter == nil {
                fpsCounter = FPSCounterView()
                addSubview(fpsCounter!)
            }
            
            if !showFPS {
                fpsCounter?.removeFromSuperview()
                fpsCounter = nil
            }
        }
    }
    
    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        super.init(frame: .zero)
    }
    
    public convenience init(model: RiveModel, autoPlay: Bool = true) {
        self.init()
        try! setModel(model, autoPlay: autoPlay)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// This resets the view with the new model. Useful when the `RiveView` was initialized without one.
    open func setModel(_ model: RiveModel, autoPlay: Bool = true) throws {
        stopTimer()
        isPlaying = false
        riveModel = model
        isOpaque = false
        
        if autoPlay {
            play()
        } else {
            advance(delta: 0)
        }
        
        showFPS = false
    }
    
    // MARK: - Controls
    
    /// Starts the render loop
    internal func play() {
        eventQueue.add {
            self.playerDelegate?.player(playedWithModel: self.riveModel)
        }
        
        isPlaying = true
        startTimer()
    }
    
    /// Asks the render loop to stop on the next cycle
    internal func pause() {
        if isPlaying {
            eventQueue.add {
                self.playerDelegate?.player(pausedWithModel: self.riveModel)
            }
            isPlaying = false
        }
    }
    
    /// Asks the render loop to stop on the next cycle
    internal func stop() {
        playerDelegate?.player(stoppedWithModel: self.riveModel)
        lastTime = 0
        
        if !isPlaying {
            advance(delta: 0)
        } else {
            isPlaying = false
        }
    }
    
    internal func reset() {
        lastTime = 0
        
        if !isPlaying {
            advance(delta: 0)
        }
    }
    
    // MARK: - Render Loop
    
    private func startTimer() {
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
    
    private func stopTimer() {
        displayLinkProxy?.invalidate()
        displayLinkProxy = nil
        lastTime = 0
        fpsCounter?.stopped()
    }
    
    /// Start a redraw:
    /// - determine the elapsed time
    /// - advance the artbaord, which will invalidate the display.
    /// - if the artboard has come to a stop, stop.
    @objc fileprivate func tick() {
        guard let displayLink = displayLinkProxy?.displayLink else {
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
        fpsCounter?.elapsed(time: elapsedTime)
        lastTime = timestamp
        advance(delta: elapsedTime)
        if !isPlaying {
            stopTimer()
        }
    }
    
    /// Advances the Artboard and either a StateMachine or an Animation.
    /// Also fires any remaining events in the queue.
    ///
    /// - Parameter delta: elapsed seconds since the last advance
    @objc open func advance(delta: Double) {
        let wasPlaying = isPlaying
        eventQueue.fireAll()
        
        if let stateMachine = riveModel.stateMachine {
            isPlaying = stateMachine.advance(by: delta) && wasPlaying
            
            stateMachine.stateChanges().forEach { stateMachineDelegate?.stateMachine?(stateMachine, didChangeState: $0) }
        }
        else if let animation = riveModel.animation {
            isPlaying = animation.advance(by: delta) && wasPlaying
            animation.apply()
            
            if isPlaying {
                if animation.didLoop() {
                    playerDelegate?.player(loopedWithModel: riveModel, type: Int(animation.loop()))
                }
            }
        }
        
        if !isPlaying {
            stopTimer()
            
            // This will be true when coming to a hault automatically
            if wasPlaying {
                playerDelegate?.player(pausedWithModel: riveModel)
            }
        }
        
        // advance the artboard
        riveModel.artboard.advance(by: delta)
        playerDelegate?.player(didAdvanceby: delta, riveModel: riveModel)
        
        // Trigger a redraw
        setNeedsDisplay()
    }
    
    /// This is called in the middle of drawRect
    override public func drawRive(_ rect: CGRect, size: CGSize) {
        // This prevents breaking when loading RiveFile from web
        guard riveModel != nil else { return }
        
        let newFrame = CGRect(origin: rect.origin, size: size)
        align(with: newFrame, contentRect: riveModel.artboard.bounds(), alignment: alignment, fit: fit)
        draw(with: riveModel.artboard)
    }
    
    // MARK: - UIResponder
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        handleTouch(location: location) { $0.touchBegan(atLocation: $1) }
        stateMachineDelegate?.touchBegan?(onArtboard: riveModel.artboard, atLocation: location)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        handleTouch(location: location) { $0.touchMoved(atLocation: $1) }
        stateMachineDelegate?.touchMoved?(onArtboard: riveModel.artboard, atLocation: location)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        handleTouch(location: location) { $0.touchEnded(atLocation: $1) }
        stateMachineDelegate?.touchEnded?(onArtboard: riveModel.artboard, atLocation: location)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        handleTouch(location: location) { $0.touchCancelled(atLocation: $1) }
        stateMachineDelegate?.touchCancelled?(onArtboard: riveModel.artboard, atLocation: location)
    }
    
    /// Sends incoming touch event to all playing `RiveStateMachineInstance`'s
    /// - Parameters:
    ///   - location: The `CGPoint` where the touch occurred in `RiveView` coordinate space
    ///   - action: Param1: A playing `RiveStateMachineInstance`, Param2: `CGPoint` location where touch occurred in `artboard` coordinate space
    private func handleTouch(location: CGPoint, action: (RiveStateMachineInstance, CGPoint)->Void) {
        let artboardLocation = artboardLocation(
            fromTouchLocation: location,
            inArtboard: riveModel.artboard.bounds(),
            fit: fit,
            alignment: alignment
        )
        
        if let stateMachine = riveModel.stateMachine {
            action(stateMachine, artboardLocation)
            play()
        }
    }
}

@objc public protocol RiveStateMachineDelegate: AnyObject {
    @objc optional func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, receivedInput input: StateMachineInput)
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String)
}

public protocol RivePlayerDelegate: AnyObject {
    func player(playedWithModel riveModel: RiveModel?)
    func player(pausedWithModel riveModel: RiveModel?)
    func player(loopedWithModel riveModel: RiveModel?, type: Int)
    func player(stoppedWithModel riveModel: RiveModel?)
    func player(didAdvanceby seconds: Double, riveModel: RiveModel?)
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

/// Tracks a queue of events that haven't been fired yet. We do this so that we're not calling delegates and modifying state
/// while a view is updating (e.g. being initialized, as we autoplay and fire play events during the view's init otherwise
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
