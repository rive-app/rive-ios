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
    internal var riveModel: NewRiveModel!
    internal var autoPlay: Bool
    internal var fit: RiveRuntime.Fit = .fitContain { didSet { setNeedsDisplay() } }
    internal var alignment: RiveRuntime.Alignment = .alignmentCenter { didSet { setNeedsDisplay() } }
    
    // MARK: Render Loop
    internal private(set) var isPlaying: Bool = false
    private var lastTime: CFTimeInterval = 0
    private var displayLinkProxy: CADisplayLinkProxy?
    private var eventQueue = EventQueue()
    
    // MARK: Delegates
    internal var playerDelegate: RivePlayerDelegate?
    internal var stateMachineDelegate: RiveStateMachineDelegate?
    
    /// Minimalist constructor, call `.configure` to customize the `RiveView` later.
    public init() {
        autoPlay = true
        super.init(frame: .zero)
    }
    
    public convenience init(model: NewRiveModel, autoPlay: Bool = true) {
        self.init()
        try! configure(model: model, autoPlay: autoPlay)
    }
    
    required public init(coder aDecoder: NSCoder) {
        autoPlay = true
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
    
    // MARK: - Controls
    
    internal func play(loop: Loop = .loopAuto, direction: Direction = .directionAuto) {
        if let animation = riveModel.animation {
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
    
    internal func pause() {
        eventQueue.add {
            self.playerDelegate?.player(pausedWithModel: self.riveModel)
        }
        
        isPlaying = false
        stopTimer()
    }
    
    internal func stop() {
        isPlaying = false
        stopTimer()
        lastTime = 0
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
    }
    
    /// Start a redraw:
    /// - determine the elapsed time
    /// - advance the artbaord, which will invalidate the display.
    /// - if the artboard has come to a stop, stop.
    @objc func tick() {
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
        eventQueue.fireAll()
        
        if let stateMachine = riveModel.stateMachine {
            isPlaying = stateMachine.advance(by: delta) && isPlaying
            stateMachine.stateChanges().forEach { stateMachineDelegate?.stateMachine?(stateMachine, didChangeState: $0) }
            
            if !isPlaying {
                pause()
            }
        }
        else if let animation = riveModel.animation {
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
        riveModel.artboard.advance(by: delta)
        playerDelegate?.player(didAdvanceby: delta, riveModel: riveModel)
        
        // Trigger a redraw
        setNeedsDisplay()
    }
    
    /// This is called in the middle of drawRect
    override public func drawRive(_ rect: CGRect, size: CGSize) {
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
        
        if isPlaying { pause() }
        else { play() }
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


public class NewRiveViewModel: NSObject, ObservableObject, RiveFileDelegate, RiveStateMachineDelegate, RivePlayerDelegate {
    var riveView: NewRiveView?
    
    public init(_ model: NewRiveModel, fit: RiveRuntime.Fit, alignment: RiveRuntime.Alignment, autoPlay: Bool) {
        self.riveModel = model
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
    }
    
    public convenience init(
        fileName: String,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        let file = try! RiveFile(name: fileName)
        var model: NewRiveModel
        
        if let name = stateMachineName {
            model = try! NewRiveModel(riveFile: file, artboardName: artboardName, stateMachineName: name)
        }
        else if let name = animationName {
            model = try! NewRiveModel(riveFile: file, artboardName: artboardName, animationName: name)
        }
        else {
            model = try! NewRiveModel(riveFile: file, artboardName: artboardName)
        }
        
        self.init(model, fit: fit, alignment: alignment, autoPlay: autoPlay)
    }
    
    // MARK: - RiveView
    
    open private(set) var riveModel: NewRiveModel? {
        didSet { riveView?.riveModel = riveModel }
    }
    
    open var isPlaying: Bool { riveView?.isPlaying ?? false }
    
    open var autoPlay: Bool = true {
        didSet { riveView?.autoPlay = autoPlay }
    }
    
    open var fit: RiveRuntime.Fit = .fitContain {
        didSet { riveView?.fit = fit }
    }
    
    open var alignment: RiveRuntime.Alignment = .alignmentCenter {
        didSet { riveView?.alignment = alignment }
    }
    
    open func play() {
        riveView?.play()
    }
    
    open func pause() {
        riveView?.pause()
    }
    
    // MARK: - StateMachine
    
    open func triggerInput(_ inputName: String) throws {
        riveModel?.stateMachine?.getTrigger(inputName)
    }
    
    open func setInput(_ inputName: String, value: Bool) throws {
        riveModel?.stateMachine?.getBool(inputName).setValue(value)
    }
    
    open func setInput(_ inputName: String, value: Float) throws {
        riveModel?.stateMachine?.getNumber(inputName).setValue(value)
    }
    
    open func setInput(_ inputName: String, value: Double) throws {
        riveModel?.stateMachine?.getNumber(inputName).setValue(Float(value))
    }
    
    // MARK: - RiveFile Delegate
    
    public func riveFileDidLoad(_ riveFile: RiveFile) throws {
        
    }
    
    // MARK: - RivePlayer Delegate
    
    open func player(playedWithModel riveModel: NewRiveModel?) { }
    open func player(pausedWithModel riveModel: NewRiveModel?) { }
    open func player(loopedWithModel riveModel: NewRiveModel?, type: Int) { }
    open func player(didAdvanceby seconds: Double, riveModel: NewRiveModel?) { }
    
    // MARK: SwiftUI Helpers
    
    /// Makes a new `RiveView` for the instance property with data from model which will
    /// replace any previous `RiveView`. This is called when first drawing a `StandardView`.
    /// - Returns: Reference to the new view that the `RiveViewModel` will be maintaining
    open func createRiveView() -> NewRiveView {
        let view: NewRiveView
        
        if let model = riveModel {
            view = NewRiveView(model: model)
        } else {
            view = NewRiveView()
        }
        
        registerView(view)
        
        return view
    }
    
    /// Gives updated layout values to the provided `RiveView`. This is called in
    /// the process of re-displaying `StandardView`.
    /// - Parameter rview: the `RiveView` that will be updated
    @objc open func update(view: NewRiveView) {
        view.fit = fit
        view.alignment = alignment
    }
    
    /// Assigns the provided `RiveView` to its rview property. This is called when creating a
    /// `StandardView`
    ///
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    fileprivate func registerView(_ view: NewRiveView) {
        riveView = view
        riveView!.playerDelegate = self
        riveView!.stateMachineDelegate = self
    }
    
    /// Stops maintaining a connection to any `RiveView`
    fileprivate func deregisterView() {
        riveView = nil
    }
    
    /// This can be added to the body of a SwiftUI `View`
    open func view() -> some View {
        return StandardView(viewModel: self)
    }
    
    /// A simple View designed to display
    public struct StandardView: View {
        let viewModel: NewRiveViewModel
        
        init(viewModel: NewRiveViewModel) {
            self.viewModel = viewModel
        }
        
        public var body: some View {
            NewRiveViewRepresentable(viewModel: viewModel)
        }
    }
    
    // MARK: UIKit Helper
    
    /// This can be used to connect with and configure an `RiveView` that was created elsewhere.
    /// Does not need to be called when updating an already configured `RiveView`. Useful for
    /// attaching views created in a `UIViewController` or Storyboard.
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    @objc open func assignView(_ view: NewRiveView) {
        registerView(view)
        
        try! riveView!.configure(model: riveModel!, autoPlay: autoPlay)
    }
}

/// This makes a SwiftUI digestable view from an `RiveViewModel` and its `RiveView`
public struct NewRiveViewRepresentable: UIViewRepresentable {
    let viewModel: NewRiveViewModel
    
    public init(viewModel: NewRiveViewModel) {
        self.viewModel = viewModel
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> NewRiveView {
        return viewModel.createRiveView()
    }
    
    public func updateUIView(_ view: NewRiveView, context: UIViewRepresentableContext<NewRiveViewRepresentable>) {
        viewModel.update(view: view)
    }
    
    public static func dismantleUIView(_ view: NewRiveView, coordinator: Coordinator) {
        view.stop()
        coordinator.viewModel.deregisterView()
    }
    
    /// Constructs a coordinator for managing updating state
    public func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
    
    public class Coordinator: NSObject {
        public var viewModel: NewRiveViewModel

        init(viewModel: NewRiveViewModel) {
            self.viewModel = viewModel
        }
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
    public convenience init(riveFile: RiveFile, artboardName: String? = nil, animationIndex index: Int? = nil) throws {
        try self.init(riveFile: riveFile, artboardName: artboardName)
        animation = try animation(index)
    }
    
    // MARK: - Factory
    
    open func artboard(_ name: String) throws -> RiveArtboard {
        do { return try riveFile.artboard(fromName: name) }
        catch { throw RiveModelError.invalidArtboard(name: name) }
    }
    
    open func artboard(_ index: Int? = nil) throws -> RiveArtboard {
        if let index = index {
            do { return try riveFile.artboard(from: index) }
            catch { throw RiveModelError.invalidArtboard(index: index) }
        } else {
            // This tries to find the 'default' Artboard
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
    
    // MARK: -
    
    public var description: String {
        let art = "RiveModel - [Artboard: " + artboard.name()
        
        if let stateMachine = stateMachine {
            return art + "StateMachine: " + stateMachine.name() + "]"
        }
        else if let animation = animation {
            return art + "Animation: " + animation.name() + "]"
        }
        else {
            return art + "]"
        }
    }
    
    enum RiveModelError: Error {
        case invalidStateMachine(name: String), invalidStateMachine(index: Int)
        case invalidAnimation(name: String), invalidAnimation(index: Int)
        case invalidArtboard(name: String), invalidArtboard(index: Int), invalidArtboard(message: String)
    }
}


