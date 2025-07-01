//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/23/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

open class RiveView: RiveRendererView {
    struct Constants {
        static let layoutScaleFactorAutomatic: Double = -1
    }

    public enum OffscreenBehavior {
        case playAndDraw
        case playAndNoDraw
    }

    // MARK: Configuration
    internal weak var riveModel: RiveModel?
    internal var fit: RiveFit = .contain { didSet { needsDisplay() } }
    internal var alignment: RiveAlignment = .center { didSet { needsDisplay() } }
    /// The scale factor to apply when using the `layout` fit. By default, this value is -1, where Rive will determine
    /// the correct scale for your device.To override this default behavior, set this value to a value greater than 0. This value should
    /// only be set at the view model level and passed into this view.
    /// - Note: If the scale factor <= 0, nothing will be drawn.
    internal var layoutScaleFactor: Double = RiveView.Constants.layoutScaleFactorAutomatic { didSet { needsDisplay() } }
    /// The internally calculated layout scale to use if a scale is not set by the developer (i.e layoutScaleFactor == -1)
    /// Defaults to the "legacy" methods, which will be overridden
    /// by window handlers in this view when the window changes.
    private lazy var _layoutScaleFactor: Double = {
        #if os(iOS) || os(visionOS) || os(tvOS)
        return self.traitCollection.displayScale
        #else
        guard let scale = NSScreen.main?.backingScaleFactor else { return 1 }
        return scale
        #endif
    }() {
        didSet { needsDisplay() }
    }
    /// Sets whether or not the Rive view should forward Rive listener touch / click events to any next responders.
    /// When true, touch / click events will be forwarded to any next responder(s).
    /// When false, only the Rive view will handle touch / click events, and will not forward
    /// to any next responder(s). Defaults to `false`, as to preserve pre-existing runtime functionality.
    /// - Note: On iOS, this is handled separately from `isExclusiveTouch`.
    internal var forwardsListenerEvents: Bool = false

    public var offscreenBehavior: OffscreenBehavior = .playAndNoDraw

    // MARK: Render Loop
    internal private(set) var isPlaying: Bool = false
    private var lastTime: CFTimeInterval = 0
    private var displaySync: RiveDisplayLink?
    private var eventQueue = EventQueue()

    // MARK: FPS
    private var userFPS: Any?
    private var userPreferredFramesPerSecond: Int? {
        return userFPS as? Int
    }
    @available(iOS 15, tvOS 15, visionOS 1, *)
    private var userPreferredFrameRateRange: CAFrameRateRange? {
        return userFPS as? CAFrameRateRange
    }

    // MARK: Delegates
    @objc public weak var playerDelegate: RivePlayerDelegate?
    public weak var stateMachineDelegate: RiveStateMachineDelegate?
    
    // MARK: Debug
    private var fpsCounter: FPSCounterView? = nil
    /// Shows or hides the FPS counter on this RiveView
    public var showFPS: Bool = RiveView.showFPSCounters { didSet { setFPSCounterVisibility() } }
    /// Shows or hides the FPS counters on all RiveViews
    public static var showFPSCounters = false

    open override var bounds: CGRect {
        didSet {
            redrawIfNecessary()
        }
    }

    open override var frame: CGRect {
        didSet {
            redrawIfNecessary()
        }
    }

    private var orientationObserver: (any NSObjectProtocol)?
    private var screenObserver: (any NSObjectProtocol)?

    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    public convenience init(model: RiveModel, autoPlay: Bool = true) {
        self.init()
        commonInit()
        try! setModel(model, autoPlay: autoPlay)
    }

    
    #if os(visionOS)
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    #else
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    #endif

    private func commonInit() {
        #if os(iOS) || os(visionOS) || os(tvOS)
        if #available(iOS 17, tvOS 17, visionOS 1, *) {
            registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { [weak self] (_: UITraitEnvironment, traitCollection: UITraitCollection) in
                guard let self else { return }
                self.redrawIfNecessary()
            }
        }

        if #available(iOS 17, tvOS 17, visionOS 1, *) {
            registerForTraitChanges([UITraitDisplayScale.self]) { [weak self] (_: UITraitEnvironment, traitCollection: UITraitCollection) in
                guard let self else { return }
                self._layoutScaleFactor = self.traitCollection.displayScale
            }
        }
        #endif

        #if os(iOS)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.redrawIfNecessary()
        }
        #endif

        #if os(macOS)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: nil,
            queue: nil) { [weak self] _ in
                guard let self, let scale = window?.screen?.backingScaleFactor else { return }
                _layoutScaleFactor = scale
            }
        #endif
    }

    deinit {
        stopTimer()
        
        #if os(iOS)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer as Any)
        }
        #endif

        #if os(macOS)
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer as Any)
        }
        #endif
        
        orientationObserver = nil
        screenObserver = nil
    }

    private func needsDisplay() {
        #if os(iOS) || os(visionOS) || os(tvOS)
        setNeedsDisplay()
        #else
        needsDisplay = true
        #endif
    }

    #if os(iOS) || os(tvOS)
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let scale = window?.windowScene?.screen.scale else { return }
        _layoutScaleFactor = scale
    }
    #elseif os(visionOS)
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        let scale = traitCollection.displayScale
        _layoutScaleFactor = scale
    }
    #else
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let scale = window?.screen?.backingScaleFactor else { return }
        _layoutScaleFactor = scale
    }
    #endif

    /// This resets the view with the new model. Useful when the `RiveView` was initialized without one.
    open func setModel(_ model: RiveModel, autoPlay: Bool = true) throws {
        stopTimer()
        isPlaying = false
        riveModel = model
        #if os(iOS) || os(visionOS) || os(tvOS)
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

    /// Hints to underlying CADisplayLink the preferred FPS to run at
    /// - Parameters:
    ///   - preferredFramesPerSecond: Integer number of seconds to set preferred FPS at
    open func setPreferredFramesPerSecond(preferredFramesPerSecond: Int) {
        userFPS = preferredFramesPerSecond
        displaySync?.set(preferredFramesPerSecond: preferredFramesPerSecond)
    }
    
    /// Hints to underlying CADisplayLink the preferred frame rate range
    /// - Parameters:
    ///   - preferredFrameRateRange: Frame rate range to set
    @available(iOS 15, macOS 14, tvOS 15, visionOS 1, *)
    open func setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange) {
        userFPS = preferredFrameRateRange
        displaySync?.set(preferredFrameRateRange: preferredFrameRateRange)
    }
    
    // MARK: - Controls
    
    /// Starts the render loop
    internal func play() {
        RiveLogger.log(view: self, event: .play)

        eventQueue.add {
            self.playerDelegate?.player(playedWithModel: self.riveModel)
        }
        
        isPlaying = true
        startTimer()
    }
    
    /// Asks the render loop to stop on the next cycle
    internal func pause() {
        RiveLogger.log(view: self, event: .pause)

        if isPlaying {
            eventQueue.add {
                self.playerDelegate?.player(pausedWithModel: self.riveModel)
            }
            isPlaying = false
        }
    }
    
    /// Asks the render loop to stop on the next cycle
    internal func stop() {
        RiveLogger.log(view: self, event: .stop)

        playerDelegate?.player(stoppedWithModel: riveModel)
        isPlaying = false
        
        reset()
    }
    
    internal func reset() {
        RiveLogger.log(view: self, event: .reset)

        lastTime = 0

        if !isPlaying {
            advance(delta: 0)
        }
    }
    
    // MARK: - Render Loop
    
    private func startTimer() {
        #if os(macOS)
        if #available(macOS 14, *) {
            guard displaySync == nil else { return }
            displaySync = RiveCADisplayLink(view: self) { [weak self] in
                self?.tick()
            }
        } else {
            guard displaySync == nil else { return }
            displaySync = RiveCVDisplaySync { [weak self] in
                self?.tick()
            }
        }
        #else
        guard displaySync == nil else { return }
        displaySync = RiveCADisplayLink(windowScene: window?.windowScene) { [weak self] in
            self?.tick()
        }
        if let fps = userPreferredFramesPerSecond {
            setPreferredFramesPerSecond(preferredFramesPerSecond: fps)
        } else if #available(iOS 15, tvOS 15, visionOS 1, *), let range = userPreferredFrameRateRange {
            setPreferredFrameRateRange(preferredFrameRateRange: range)
        }
        #endif
        displaySync?.start()
    }
    
    private func stopTimer() {
        displaySync?.stop()
        displaySync = nil
        lastTime = 0
        fpsCounter?.stopped()
    }
    
    private func timestamp() -> CFTimeInterval {
        return displaySync?.targetTimestamp ?? Date().timeIntervalSince1970
    }
        
    
    /// Start a redraw:
    /// - determine the elapsed time
    /// - advance the artbaord, which will invalidate the display.
    /// - if the artboard has come to a stop, stop.
    @objc fileprivate func tick() {
        guard displaySync != nil else {
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
        
        #if os(iOS) || os(visionOS) || os(tvOS)
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
                    RiveLogger.log(view: self, event: .eventReceived(event.name()))
                    stateMachineDelegate?.onRiveEventReceived?(onRiveEvent: event)
                }
            }
            var shouldAdvance = stateMachine.advance(by: delta)
            if delta == 0 {
                shouldAdvance = true
            }
            isPlaying = shouldAdvance && wasPlaying

            if let delegate = stateMachineDelegate {
                stateMachine.stateChanges().forEach { delegate.stateMachine?(stateMachine, didChangeState: $0) }
            }

            stateMachine.viewModelInstance?.updateListeners()
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
                RiveLogger.log(view: self, event: .pause)
                playerDelegate?.player(pausedWithModel: riveModel)
            }
        }
        
        RiveLogger.log(view: self, event: .advance(delta))
        playerDelegate?.player(didAdvanceby: delta, riveModel: riveModel)
        
        // Trigger a redraw
        needsDisplay()
    }
    /// This is called in the middle of drawRect. Override this method to implement
    /// custom draw logic
    override open func drawRive(_ rect: CGRect, size: CGSize) {
        // This prevents breaking when loading RiveFile async
        guard let artboard = riveModel?.artboard else { return }

        let scale = layoutScaleFactor == RiveView.Constants.layoutScaleFactorAutomatic ? _layoutScaleFactor : layoutScaleFactor

        RiveLogger.log(view: self, event: .drawing(size))
        let newFrame = CGRect(origin: rect.origin, size: size)
        if (fit == RiveFit.layout) {
            if scale <= 0 {
                RiveLogger.log(view: self, event: .error("Cannot draw with a scale factor of \(scale)"))
                return
            }
            artboard.setWidth(Double(newFrame.width) / scale);
            artboard.setHeight(Double(newFrame.height) / scale);
        } else {
            artboard.resetArtboardSize();
        }
        align(with: newFrame, contentRect: artboard.bounds(), alignment: alignment, fit: fit, scaleFactor: scale)
        draw(with: artboard)

    }

    open override func draw(_ rect: CGRect) {
        if offscreenBehavior == .playAndDraw || isOnscreen() {
            super.draw(rect)
        }
    }

    // MARK: - UITraitCollection
    #if os(iOS)
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #unavailable(iOS 17) {
            if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass
                || traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
                redrawIfNecessary()
            }

            if traitCollection.displayScale != previousTraitCollection?.displayScale {
                _layoutScaleFactor = traitCollection.displayScale
            }
        }
    }
    #endif

    // MARK: - UIResponder
    #if os(iOS) || os(visionOS) || os(tvOS)
        open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            
            handleTouch(touch, delegate: stateMachineDelegate?.touchBegan) { stateMachine, location in
                let result = stateMachine.touchBegan(atLocation: location)
                RiveLogger.log(view: self, event: .touchBegan(location))

                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .began)
                }
            }

            if forwardsListenerEvents == true {
                super.touchesBegan(touches, with: event)
            }
        }
        
        open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }

            handleTouch(touch, delegate: stateMachineDelegate?.touchMoved) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchMoved(location))

                let result = stateMachine.touchMoved(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .moved)
                }
            }

            if forwardsListenerEvents == true {
                super.touchesMoved(touches, with: event)
            }
        }
        
        open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }

            handleTouch(touch, delegate: stateMachineDelegate?.touchEnded) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchEnded(location))

                let result = stateMachine.touchEnded(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .ended)
                }
            }

            if forwardsListenerEvents == true {
                super.touchesEnded(touches, with: event)
            }
        }
        
        open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }

            handleTouch(touch, delegate: stateMachineDelegate?.touchCancelled) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchCancelled(location))

                let result = stateMachine.touchCancelled(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .cancelled)
                }
            }

            if forwardsListenerEvents == true {
                super.touchesCancelled(touches, with: event)
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
            handleTouch(event, delegate: stateMachineDelegate?.touchBegan) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchBegan(location))

                let result = stateMachine.touchBegan(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .began)
                }
            }

            if forwardsListenerEvents == true {
                super.mouseDown(with: event)
            }
        }
        
        open override func mouseMoved(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchMoved) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchMoved(location))

                let result = stateMachine.touchMoved(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .moved)
                }
            }

            if forwardsListenerEvents == true {
                super.mouseMoved(with: event)
            }
        }
        
        open override func mouseDragged(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchMoved) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchMoved(location))

                let result = stateMachine.touchMoved(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .moved)
                }
            }

            if forwardsListenerEvents == true {
                super.mouseDragged(with: event)
            }
        }
        
        open override func mouseUp(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchEnded) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchEnded(location))

                let result = stateMachine.touchEnded(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .ended)
                }
            }

            if forwardsListenerEvents == true {
                super.mouseUp(with: event)
            }
        }
        
        open override func mouseExited(with event: NSEvent) {
            handleTouch(event, delegate: stateMachineDelegate?.touchCancelled) { stateMachine, location in
                RiveLogger.log(view: self, event: .touchCancelled(location))

                let result = stateMachine.touchCancelled(atLocation: location)
                if let stateMachine = riveModel?.stateMachine {
                    stateMachineDelegate?.stateMachine?(stateMachine, didReceiveHitResult: result, from: .cancelled)
                }
            }

            if forwardsListenerEvents == true {
                super.mouseExited(with: event)
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

    private func redrawIfNecessary() {
        if isPlaying == false {
            needsDisplay()
        }
    }
}

/// An enum of possible touch or mouse events when interacting with an animation.
@objc public enum RiveTouchEvent: Int {
    /// The touch event that occurs when a touch or mouse button click occurs.
    case began
    /// The touch event that occurs when a touch or mouse is dragged.
    case moved
    /// The touch event that occurs when a touch or mouse button is lifted.
    case ended
    /// The touch event that occurs when a touch or mouse click is cancelled.
    case cancelled
}

@objc public protocol RiveStateMachineDelegate: AnyObject {
    @objc optional func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, receivedInput input: StateMachineInput)
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String)
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, didReceiveHitResult hitResult: RiveHitResult, from event: RiveTouchEvent)
    @objc optional func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent)
}

@objc public protocol RivePlayerDelegate: AnyObject {
    func player(playedWithModel riveModel: RiveModel?)
    func player(pausedWithModel riveModel: RiveModel?)
    func player(loopedWithModel riveModel: RiveModel?, type: Int)
    func player(stoppedWithModel riveModel: RiveModel?)
    func player(didAdvanceby seconds: Double, riveModel: RiveModel?)
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
