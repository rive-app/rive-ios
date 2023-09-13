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
    internal weak var riveModel: RiveModel?
    internal var fit: RiveFit = .contain { didSet { needsDisplay() } }
    internal var alignment: RiveAlignment = .center { didSet { needsDisplay() } }
    
    // MARK: Render Loop
    internal private(set) var isPlaying: Bool = false
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: DisplayLinkProxy?
    private var eventQueue = EventQueue()
    
    // MARK: Delegates
    public weak var playerDelegate: RivePlayerDelegate?
    public weak var stateMachineDelegate: RiveStateMachineDelegate?
    
    // MARK: Debug
    private var fpsCounter: FPSCounterView? = nil
    /// Shows or hides the FPS counter on this RiveView
    public var showFPS: Bool = RiveView.showFPSCounters { didSet { setFPSCounterVisibility() } }
    /// Shows or hides the FPS counters on all RiveViews
    public static var showFPSCounters = false
    
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
    
    private func needsDisplay() {
        #if os(iOS)
            setNeedsDisplay()
        #else
            needsDisplay=true
        #endif
    }
    
    /// This resets the view with the new model. Useful when the `RiveView` was initialized without one.
    open func setModel(_ model: RiveModel, autoPlay: Bool = true) throws {
        stopTimer()
        isPlaying = false
        riveModel = model
        #if os(iOS)
            isOpaque = false
        #else
            layer?.isOpaque=false
        #endif
        
        
        if autoPlay {
            play()
        } else {
            advance(delta: 0)
        }
        
        setFPSCounterVisibility()
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
        playerDelegate?.player(stoppedWithModel: riveModel)
        isPlaying = false
        
        reset()
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
            displayLinkProxy = DisplayLinkProxy(
                handle: { [weak self] in
                    self?.tick()
                },
                to: .main,
                forMode: .common
            )
        }
        #if os(iOS)
            if displayLinkProxy?.displayLink?.isPaused == true {
                displayLinkProxy?.displayLink?.isPaused = false
            }
        #endif
    }
    
    private func stopTimer() {
        displayLinkProxy?.invalidate()
        displayLinkProxy = nil
        lastTime = 0
        fpsCounter?.stopped()
    }
    
    private func timestamp() -> Double {
        return Date().timeIntervalSince1970
    }
        
    
    /// Start a redraw:
    /// - determine the elapsed time
    /// - advance the artbaord, which will invalidate the display.
    /// - if the artboard has come to a stop, stop.
    @objc fileprivate func tick() {
        guard displayLinkProxy?.displayLink != nil else {
            stopTimer()
            return
        }
        
        let timestamp = timestamp()
        // last time needs to be set on the first tick
        if lastTime == 0 {
            lastTime = timestamp
        }
        
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime
        
        #if os(iOS)
            fpsCounter?.didDrawFrame(timestamp: timestamp)
        #else
            fpsCounter?.elapsed(time: elapsedTime)
        #endif
            
        
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
        
        if let stateMachine = riveModel?.stateMachine {
            let firedEventCount = stateMachine.reportedEventCount()
            if (firedEventCount > 0) {
                for i in 0..<firedEventCount {
                    let event = stateMachine.reportedEvent(at: i)
                    stateMachineDelegate?.onRiveEventReceived?(onRiveEvent: event)
                }
            }    
            isPlaying = stateMachine.advance(by: delta) && wasPlaying
            stateMachine.stateChanges().forEach { stateMachineDelegate?.stateMachine?(stateMachine, didChangeState: $0) }
        } else if let animation = riveModel?.animation {
            isPlaying = animation.advance(by: delta) && wasPlaying
            
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
        
        playerDelegate?.player(didAdvanceby: delta, riveModel: riveModel)
        
        // Trigger a redraw
        needsDisplay()
    }
    
    /// This is called in the middle of drawRect
    override public func drawRive(_ rect: CGRect, size: CGSize) {
        // This prevents breaking when loading RiveFile async
        guard let artboard = riveModel?.artboard else { return }
        
        let newFrame = CGRect(origin: rect.origin, size: size)
        align(with: newFrame, contentRect: artboard.bounds(), alignment: alignment, fit: fit)
        draw(with: artboard)
        
    }
    
    // MARK: - UIResponder
    #if os(iOS)
        open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            handleTouch(touches.first!, delegate: stateMachineDelegate?.touchBegan) {
                $0.touchBegan(atLocation: $1)
            }
        }
        
        open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            handleTouch(touches.first!, delegate: stateMachineDelegate?.touchMoved) {
                $0.touchMoved(atLocation: $1)
            }
        }
        
        open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            handleTouch(touches.first!, delegate: stateMachineDelegate?.touchEnded) {
                $0.touchEnded(atLocation: $1)
            }
        }
        
        open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            handleTouch(touches.first!, delegate: stateMachineDelegate?.touchCancelled) {
                $0.touchCancelled(atLocation: $1)
            }
        }
        
        /// Sends incoming touch event to all playing `RiveStateMachineInstance`'s
        /// - Parameters:
        ///   - touch: The `CGPoint` where the touch occurred in `RiveView` coordinate space
        ///   - delegateAction: The delegate callback that should be triggered by this touch event
        ///   - stateMachineAction: Param1: A playing `RiveStateMachineInstance`, Param2: `CGPoint`
        ///   location where touch occurred in `artboard` coordinate space
        private func handleTouch(
            _ touch: UITouch,
            delegate delegateAction: ((RiveArtboard?, CGPoint)->Void)?,
            stateMachineAction: (RiveStateMachineInstance, CGPoint)->Void
        ) {
            guard let artboard = riveModel?.artboard else { return }
            guard let stateMachine = riveModel?.stateMachine else { return }
            let location = touch.location(in: self)
            
            let artboardLocation = artboardLocation(
                fromTouchLocation: location,
                inArtboard: artboard.bounds(),
                fit: fit,
                alignment: alignment
            )
            
            stateMachineAction(stateMachine, artboardLocation)
            play()
            
            // We send back the touch location in UIView coordinates because
            // users cannot query or manually control the coordinates of elements
            // in the Artboard. So that information would be of no use.
            delegateAction?(artboard, location)
        }
    #else
        open override func mouseDown(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchBegan) {
                $0.touchBegan(atLocation: $1)
            }
        }
        
        open override func mouseMoved(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchMoved) {
                $0.touchMoved(atLocation: $1)
            }
        }
        
        open override func mouseDragged(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchMoved) {
                $0.touchMoved(atLocation: $1)
            }
        }
        
        open override func mouseUp(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchEnded) {
                $0.touchEnded(atLocation: $1)
            }
        }
        
        open override func mouseExited(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchCancelled) {
                $0.touchCancelled(atLocation: $1)
            }
        }
        
        open override func updateTrackingAreas() {
            addTrackingArea(
                NSTrackingArea(
                    rect: self.bounds,
                    options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow],
                    owner: self,
                    userInfo: nil
                )
            )
        }
        
        /// Sends incoming touch event to all playing `RiveStateMachineInstance`'s
        /// - Parameters:
        ///   - touch: The `CGPoint` where the touch occurred in `RiveView` coordinate space
        ///   - delegateAction: The delegate callback that should be triggered by this touch event
        ///   - stateMachineAction: Param1: A playing `RiveStateMachineInstance`, Param2: `CGPoint`
        ///   location where touch occurred in `artboard` coordinate space
        private func handleTouch(
            _ event: NSEvent,
            delegate delegateAction: ((RiveArtboard?, CGPoint)->Void)?,
            stateMachineAction: (RiveStateMachineInstance, CGPoint)->Void
        ) {
            guard let artboard = riveModel?.artboard else { return }
            guard let stateMachine = riveModel?.stateMachine else { return }
            let location = convert(event.locationInWindow, from: nil)
            
            // This is conforms the point to UIView coordinates which the
            // RiveRendererView expects in its artboardLocation method
            let locationFlippedY = CGPoint(x: location.x, y: frame.height - location.y)
            
            let artboardLocation = artboardLocation(
                fromTouchLocation: locationFlippedY,
                inArtboard: artboard.bounds(),
                fit: fit,
                alignment: alignment
            )
            
            stateMachineAction(stateMachine, artboardLocation)
            play()
            
            // We send back the touch location in NSView coordinates because
            // users cannot query or manually control the coordinates of elements
            // in the Artboard. So that information would be of no use.
            delegateAction?(artboard, location)
        }
    #endif
    
    // MARK: - Debug
    
    private func setFPSCounterVisibility() {
        // Create a new counter view
        if showFPS && fpsCounter == nil {
            fpsCounter = FPSCounterView()
            addSubview(fpsCounter!)
        }
        
        if !showFPS {
            fpsCounter?.removeFromSuperview()
            fpsCounter = nil
        }
    }
    
    deinit {
        stopTimer()
    }
}

@objc public protocol RiveStateMachineDelegate: AnyObject {
    @objc optional func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, receivedInput input: StateMachineInput)
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String)
    @objc optional func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent)
}

public protocol RivePlayerDelegate: AnyObject {
    func player(playedWithModel riveModel: RiveModel?)
    func player(pausedWithModel riveModel: RiveModel?)
    func player(loopedWithModel riveModel: RiveModel?, type: Int)
    func player(stoppedWithModel riveModel: RiveModel?)
    func player(didAdvanceby seconds: Double, riveModel: RiveModel?)
}

#if os(iOS)
    fileprivate class DisplayLinkProxy {
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
#else
    fileprivate class DisplayLinkProxy {
        var displayLink: CVDisplayLink?
        
        init?(handle: (() -> Void)!, to runloop: RunLoop, forMode mode: RunLoop.Mode) {
            //ignore runloop/formode
            let error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
            if error != kCVReturnSuccess { return nil }
            
            CVDisplayLinkSetOutputHandler(displayLink!) { dl, ts, tsDisplay, _, _ in
                DispatchQueue.main.async {
                    handle()
                }
                return kCVReturnSuccess
            }
            
            CVDisplayLinkStart(displayLink!)
        }

        func invalidate() {
            
            if let displayLink = displayLink {
                CVDisplayLinkStop(displayLink)
                self.displayLink = nil
            }
        }
    }
#endif

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
