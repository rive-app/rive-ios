//
//  NewRiveView.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 5/3/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

@objc public protocol RiveStateMachineDelegate: AnyObject {
    @objc optional func touchBegan(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchMoved(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchEnded(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    @objc optional func touchCancelled(onArtboard artboard: RiveArtboard?, atLocation location: CGPoint)
    
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, receivedInput input: StateMachineInput)
    @objc optional func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String)
}

public protocol RivePlayerDelegate: AnyObject {
    func player(playedWithModel riveModel: NewRiveModel?)
    func player(pausedWithModel riveModel: NewRiveModel?)
    func player(loopedWithModel riveModel: NewRiveModel?, type: Int)
    func player(didAdvanceby seconds: Double, riveModel: NewRiveModel?)
}

open class NewRiveView: RiveRendererView {
    var riveModel: NewRiveModel?
    
    // Render Loop
    open private(set) var isPlaying: Bool = false
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: CADisplayLinkProxy?
    private var eventQueue = EventQueue()
    public var fit: RiveRuntime.Fit = .fitContain { didSet { setNeedsDisplay() } }
    public var alignment: RiveRuntime.Alignment = .alignmentCenter { didSet { setNeedsDisplay() } }
    
    // Delegates
    private var playerDelegate: RivePlayerDelegate?
    private var stateMachineDelegate: RiveStateMachineDelegate?
    
    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        super.init(frame: .zero)
    }
    
    public convenience init(model: NewRiveModel, autoPlay: Bool = true) {
        self.init()
        try! configure(model: model, autoPlay: autoPlay)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open func configure(model: NewRiveModel, autoPlay: Bool = true) throws {
        stop()
        self.riveModel = model
        isOpaque = false
        
        if autoPlay {
            play()
        } else {
            advance(delta: 0)
        }
    }
    
    open func play(loop: Loop = .loopAuto, direction: Direction = .directionAuto) {
        if let animation = riveModel?.animation {
            if loop != .loopAuto {
                animation.loop(Int32(loop.rawValue))
            }
            
            if direction == .directionForwards {
                animation.direction(1)
            } else if direction == .directionBackwards {
                animation.direction(-1)
            }
        }
        
        eventQueue.add {
            self.playerDelegate?.player(playedWithModel: self.riveModel)
        }
        
        isPlaying = true
        startTimer()
    }
    
    open func pause() {
        eventQueue.add {
            self.playerDelegate?.player(pausedWithModel: self.riveModel)
        }
        
        isPlaying = false
        stopTimer()
    }
    
    private func stop() {
        isPlaying = false
        stopTimer()
        lastTime = 0
    }
    
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
        let elapsedTime = timestamp - lastTime
        lastTime = timestamp
        advance(delta: elapsedTime)
        if !isPlaying {
            stopTimer()
        }
    }
    
    /// Advance all playing animations by a set amount.
    ///
    /// This will also trigger any events for configured delegates.
    /// - Parameter delta: elapsed seconds.
    @objc open func advance(delta: Double) {
        eventQueue.fireAll()
        
        if let stateMachine = riveModel?.stateMachine {
            isPlaying = stateMachine.advance(by: delta) && isPlaying
            stateMachine.stateChanges().forEach { stateMachineDelegate?.stateMachine?(stateMachine, didChangeState: $0) }
            
            if !isPlaying {
                pause()
            }
        }
        else if let animation = riveModel?.animation {
            isPlaying = animation.advance(by: delta) && isPlaying
            animation.apply()
            
            if !isPlaying {
                pause()
            } else {
                if animation.didLoop() {
                    playerDelegate?.player(loopedWithModel: riveModel, type: Int(animation.loop()))
                }
            }
        }
        
        // advance the artboard
        riveModel?.artboard.advance(by: delta)
        playerDelegate?.player(didAdvanceby: delta, riveModel: riveModel)
        
        // Trigger a redraw
        setNeedsDisplay()
    }
    
    override public func drawRive(_ rect: CGRect, size: CGSize) {
        guard let artboard = riveModel?.artboard else { return }
        let alignmentRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: size.width, height: size.height)
        
        align(with: alignmentRect, contentRect: artboard.bounds(), alignment: alignment, fit: fit)
        draw(with: artboard)
    }
    
    // MARK: - UIResponder
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        handleTouch(location: location) { $0.touchBegan(atLocation: $1) }
        stateMachineDelegate?.touchBegan?(onArtboard: riveModel?.artboard, atLocation: location)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        handleTouch(location: location) { $0.touchMoved(atLocation: $1) }
        stateMachineDelegate?.touchMoved?(onArtboard: riveModel?.artboard, atLocation: location)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        handleTouch(location: location) { $0.touchEnded(atLocation: $1) }
        stateMachineDelegate?.touchEnded?(onArtboard: riveModel?.artboard, atLocation: location)
        
        if isPlaying { pause() }
        else { play() }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        handleTouch(location: location) { $0.touchCancelled(atLocation: $1) }
        stateMachineDelegate?.touchCancelled?(onArtboard: riveModel?.artboard, atLocation: location)
    }
    
    /// Sends incoming touch event to all playing `RiveStateMachineInstance`'s
    /// - Parameters:
    ///   - location: The `CGPoint` where the touch occurred in `RiveView` coordinate space
    ///   - action: Param1: A playing `RiveStateMachineInstance`, Param2: `CGPoint` location where touch occurred in `artboard` coordinate space
    private func handleTouch(location: CGPoint, action: (RiveStateMachineInstance, CGPoint)->Void) {
        let artboardLocation = artboardLocation(
            fromTouchLocation: location,
            inArtboard: riveModel!.artboard.bounds(),
            fit: fit,
            alignment: alignment
        )
        
        if let stateMachine = riveModel!.stateMachine {
            action(stateMachine, artboardLocation)
            play()
        }
    }
}

public struct NewRiveViewRepresentable: UIViewRepresentable {
    public typealias UIViewType = NewRiveView
    
    var riveView: NewRiveView
    
    public init(view: NewRiveView) {
        self.riveView = view
    }
    
    public func makeUIView(context: Context) -> NewRiveView {
        return riveView
    }
    
    public func updateUIView(_ uiView: NewRiveView, context: Context) {
//        riveView = uiView
    }
}


open class NewRiveModel: ObservableObject {
    private var riveFile: RiveFile
    public private(set) var artboard: RiveArtboard
    public private(set) var stateMachine: RiveStateMachineInstance?
    public private(set) var animation: RiveLinearAnimationInstance?
    
    // Artboard - specified name or defaults to the 'default' in the file
    private init(riveFile: RiveFile, artboardName name: String? = nil) throws {
        self.riveFile = riveFile
        
        if let name = name {
            do { artboard = try riveFile.artboard(fromName: name) }
            catch { throw RiveModelError.invalidArtboard(name: name) }
        } else {
            do { artboard = try riveFile.artboard() }
            catch { throw RiveModelError.invalidArtboard(message: "No Default Artboard") }
        }
    }

    // StateMachine - specified name or defaults to the first in the Artboard
    public convenience init(riveFile: RiveFile, artboardName: String? = nil, stateMachineName: String?) throws {
        try self.init(riveFile: riveFile, artboardName: artboardName)
        
        if let name = stateMachineName {
            stateMachine = try stateMachine(name)
        } else {
            stateMachine = try stateMachine()
        }
    }
    
    // StateMachine - specified index or defaults to the first in the Artboard
    public convenience init(riveFile: RiveFile, artboardName: String? = nil, stateMachineIndex index: Int?) throws {
        try self.init(riveFile: riveFile, artboardName: artboardName)
        stateMachine = try stateMachine(index)
    }
    
    // Animation - specified name or defaults to the first in the Artboard
    public convenience init(riveFile: RiveFile, artboardName: String? = nil, animationName: String?) throws {
        try self.init(riveFile: riveFile, artboardName: artboardName)
        
        if let name = animationName {
            animation = try animation(name)
        } else {
            animation = try animation()
        }
    }
    
    // Animation - specified index or defaults to the first in the Artboard
    public convenience init(riveFile: RiveFile, artboardName: String? = nil, animationIndex index: Int?) throws {
        try self.init(riveFile: riveFile, artboardName: artboardName)
        animation = try animation(index)
    }
    
    // MARK: - Factory
    
    open func artboard(name: String? = nil) throws -> RiveArtboard {
        if let name = name {
            do { return try riveFile.artboard(fromName: name) }
            catch { throw RiveModelError.invalidArtboard(name: name) }
        } else {
            do { return try riveFile.artboard() }
            catch { throw RiveModelError.invalidArtboard(message: "No Default Artboard") }
        }
    }
    
    open func stateMachine(_ name: String) throws -> RiveStateMachineInstance {
        do { return try artboard.stateMachine(fromName: name) }
        catch { throw RiveModelError.invalidStateMachine(name: name) }
    }
    
    open func stateMachine(_ index: Int? = nil) throws -> RiveStateMachineInstance {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { return try artboard.stateMachine(from: index) }
        catch { throw RiveModelError.invalidStateMachine(index: index) }
    }
    
    open func animation(_ name: String) throws -> RiveLinearAnimationInstance {
        do { return try artboard.animation(fromName: name) }
        catch { throw RiveModelError.invalidAnimation(name: name) }
    }
    
    open func animation(_ index: Int? = nil) throws -> RiveLinearAnimationInstance {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { return try artboard.animation(from: index) }
        catch { throw RiveModelError.invalidAnimation(index: index) }
    }
}


class NewRiveViewModel: NSObject, ObservableObject, RiveFileDelegate {
    var riveFile: RiveFile?
    
    init(fileName: String, artboardName: String? = nil, stateMachineName: String?) throws {
        riveFile = try RiveFile(name: fileName)
    }
    
    init(webURL: String) throws {
        super.init()
    }
    
    // RiveFile + StateMachine Name
    init(riveFile: RiveFile, artboardName: String? = nil, stateMachineName: String?) throws {
        
    }
    
    // RiveFile + StateMachine Index
    init(riveFile: RiveFile, artboardName: String? = nil, stateMachineIndex index: Int?) throws {

    }

    // RiveFile + Animation Name
    init(riveFile: RiveFile, artboardName: String? = nil, animationName: String?) throws {

    }

    // RiveFile + Animation Index
    init(riveFile: RiveFile, artboardName: String? = nil, animationIndex index: Int?) throws {

    }
    
    func riveFileDidLoad(_ riveFile: RiveFile) throws {
        self.riveFile = riveFile
    }
}

enum RiveModelError: Error {
    case invalidStateMachine(name: String), invalidStateMachine(index: Int)
    case invalidAnimation(name: String), invalidAnimation(index: Int)
    case invalidArtboard(name: String), invalidArtboard(message: String)
}


//struct RTestView: View {
//    var riveFile = try! RiveFile(name: "truck")
//
//    var body: some View {
//        NewRiveViewRepresentable(view: NewRiveView(file: riveFile))
//    }
//}
//
//struct RTestView_Previews: PreviewProvider {
//    static var previews: some View {
//        RTestView()
//    }
//}
