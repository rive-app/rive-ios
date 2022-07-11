//
//  RiveViewModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import Combine

/// An object used for controlling a RiveView. For most common Rive files you should only need
/// to interact with a `RiveViewModel` object.
///
/// - Usage:
///   - You should initialize with either an Animation name or a StateMachine name, but not both.
///   Only one will be used and if both are given the StateMachine will be used.
///   - Default StateMachine or Animation from the file can be used by leaving their parameters nil
/// - Examples:
///
/// ```
/// // SwiftUI Example
/// struct Animation: View {
///     var body: some View {
///         RiveViewModel(fileName: "cool_rive_file").view()
///     }
/// }
/// ```
///
/// ```
/// // UIKit Example
/// class AnimationViewController: UIViewController {
///    @IBOutlet weak var riveView: RiveView!
///    var viewModel = RiveViewModel(fileName: "cool_rive_file")
///
///    override func viewDidLoad() {
///       viewModel.setView(riveView)
///    }
/// }
/// ```
open class RiveViewModel: NSObject, ObservableObject, RiveFileDelegate, RiveStateMachineDelegate, RivePlayerDelegate {
    open private(set) var riveView: RiveView?
    private var defaultModel: RiveModelBuffer!
    
    public init(
        _ model: RiveModel,
        stateMachineName: String?,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = model
        sharedInit(artboardName: artboardName, stateMachineName: stateMachineName, animationName: nil)
    }
    
    public init(
        _ model: RiveModel,
        animationName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = model
        sharedInit(artboardName: artboardName, stateMachineName: nil, animationName: animationName)
    }
    
    public init(
        fileName: String,
        stateMachineName: String?,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = try! RiveModel(fileName: fileName)
        sharedInit(artboardName: artboardName, stateMachineName: stateMachineName, animationName: nil)
    }
    
    public init(
        fileName: String,
        animationName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = try! RiveModel(fileName: fileName)
        sharedInit(artboardName: artboardName, stateMachineName: nil, animationName: animationName)
    }
    
    public init(
        webURL: String,
        stateMachineName: String?,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = RiveModel(webURL: webURL, delegate: self)
        defaultModel = RiveModelBuffer(artboardName: artboardName, stateMachineName: stateMachineName, animationName: nil)
    }
    
    public init(
        webURL: String,
        animationName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = RiveModel(webURL: webURL, delegate: self)
        defaultModel = RiveModelBuffer(artboardName: artboardName, stateMachineName: nil, animationName: animationName)
    }
    
    private func sharedInit(artboardName: String?, stateMachineName: String?, animationName: String?) {
        try! configureModel(artboardName: artboardName, stateMachineName: stateMachineName, animationName: animationName)
        
        defaultModel = RiveModelBuffer(
            artboardName: artboardName,
            stateMachineName: stateMachineName,
            animationName: animationName
        )
        
        try! riveView?.setModel(riveModel!, autoPlay: autoPlay)
    }
    
    // MARK: - RiveView
    
    open private(set) var riveModel: RiveModel? {
        didSet {
            if let model = riveModel {
                try! riveView?.setModel(model, autoPlay: autoPlay)
            }
        }
    }
    
    open var isPlaying: Bool { riveView?.isPlaying ?? false }
    
    open var autoPlay: Bool
    
    open var fit: RiveRuntime.Fit = .fitContain {
        didSet { riveView?.fit = fit }
    }
    
    open var alignment: RiveRuntime.Alignment = .alignmentCenter {
        didSet { riveView?.alignment = alignment }
    }
    
    /// Starts the active Animation or StateMachine from it's last position. It will start
    /// from the beginning if the active Animation has ended or a new one is provided.
    /// - Parameters:
    ///   - animationName: The name of a new Animation to play on the current Artboard
    ///   - loop: The loop mode for the active Animation
    open func play(animationName: String? = nil, loop: Loop = .loopAuto, direction: Direction = .directionAuto) {
        if let name = animationName {
            try! riveModel?.setAnimation(name)
        }
        
        if let animation = riveModel?.animation {
            if loop != .loopAuto {
                animation.loop(Int32(loop.rawValue))
            }
            
            if direction == .directionForwards {
                animation.direction(1)
            } else if direction == .directionBackwards {
                animation.direction(-1)
            }
            
            if animation.hasEnded() {
                // Restarts Animation from beginning
                animation.setTime(0)
            }
        }
        
        // We're not checking if a StateMachine is "ended" or "ExitState"
        // But we may want to in the future to enable restarting it by playing again
        
        riveView?.play()
    }
    
    /// Halts the active Animation or StateMachine and will resume from it's current position when next played
    open func pause() {
        riveView?.pause()
    }
    
    /// Halts the active Animation or StateMachine and sets it at its starting position
    open func stop() {
        resetCurrentModel()
        riveView?.stop()
    }
    
    /// Sets the active Animation or StateMachine back to their starting position
    open func reset() {
        resetCurrentModel()
        riveView?.reset()
    }
    
    // MARK: - RiveModel
    
    /// Instantiates elements in the model needed to play in a `RiveView`
    private func configureModel(artboardName: String? = nil, stateMachineName: String? = nil, animationName: String? = nil) throws {
        guard let model = riveModel else { fatalError("Cannot configure nil RiveModel") }
        
        if let name = artboardName {
            try model.setArtboard(name)
        } else {
            // Keep current Artboard if there is one
            if model.artboard == nil {
                // Set default Artboard if not
                try model.setArtboard()
            }
        }
        
        model.animation = nil
        model.stateMachine = nil
        
        if let name = stateMachineName {
            try model.setStateMachine(name)
        }
        else if let name = animationName {
            try model.setAnimation(name)
        }
        else {
            try model.setDefaultScene()
        }
    }
    
    /// Puts the active Animation or StateMachine back to their starting position
    private func resetCurrentModel() {
        guard let model = riveModel else { fatalError("Current model is nil") }
        try! configureModel(
            artboardName: model.artboard.name(),
            stateMachineName: model.stateMachine?.name(),
            animationName: model.animation?.name()
        )
    }
    
    /// Sets the Artboard, StateMachine or Animation back to the first one given to the RiveViewModel
    open func resetToDefaultModel() {
        try! configureModel(
            artboardName: defaultModel.artboardName,
            stateMachineName: defaultModel.stateMachineName,
            animationName: defaultModel.animationName
        )
    }
    
    
    /// Provide the active StateMachine a `Trigger` input
    /// - Parameter inputName: The name of a `Trigger` input on the active StateMachine
    open func triggerInput(_ inputName: String) {
        riveModel?.stateMachine?.getTrigger(inputName).fire()
        play()
    }
    
    /// Provide the active StateMachine a `Boolean` input
    /// - Parameters:
    ///   - inputName: The name of a `Boolean` input on the active StateMachine
    ///   - value: A Bool value for the input
    open func setInput(_ inputName: String, value: Bool) {
        riveModel?.stateMachine?.getBool(inputName).setValue(value)
        play()
    }
    
    /// Provide the active StateMachine a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Float value for the input
    open func setInput(_ inputName: String, value: Float) {
        riveModel?.stateMachine?.getNumber(inputName).setValue(value)
        play()
    }
    
    /// Provide the active StateMachine a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Double value for the input
    open func setInput(_ inputName: String, value: Double) {
        setInput(inputName, value: Float(value))
    }
    
    // MARK: - SwiftUI Helpers
    
    /// Makes a new `RiveView` for the instance property with data from model which will
    /// replace any previous `RiveView`. This is called when first drawing a `RiveViewRepresentable`.
    /// - Returns: Reference to the new view that the `RiveViewModel` will be maintaining
    open func createRiveView() -> RiveView {
        let view: RiveView
        
        if let model = riveModel {
            view = RiveView(model: model, autoPlay: autoPlay)
        } else {
            view = RiveView()
        }
        
        registerView(view)
        
        return view
    }
    
    /// Gives updated layout values to the provided `RiveView`. This is called in
    /// the process of re-displaying `RiveViewRepresentable`.
    /// - Parameter rview: the `RiveView` that will be updated
    @objc open func update(view: RiveView) {
        view.fit = fit
        view.alignment = alignment
    }
    
    /// Assigns the provided `RiveView` to its rview property. This is called when creating a
    /// `RiveViewRepresentable`
    ///
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    fileprivate func registerView(_ view: RiveView) {
        riveView = view
        riveView!.playerDelegate = self
        riveView!.stateMachineDelegate = self
    }
    
    /// Stops maintaining a connection to any `RiveView`
    fileprivate func deregisterView() {
        riveView = nil
    }
    
    /// This can be added to the body of a SwiftUI `View`
    open func view() -> AnyView {
        return AnyView(RiveViewRepresentable(viewModel: self))
    }
    
    // MARK: - UIKit Helper
    
    /// This can be used to connect with and configure an `RiveView` that was created elsewhere.
    /// Does not need to be called when updating an already configured `RiveView`. Useful for
    /// attaching views created in a `UIViewController` or Storyboard.
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    @objc open func setView(_ view: RiveView) {
        registerView(view)
        try! riveView!.setModel(riveModel!, autoPlay: autoPlay)
    }
    
    // MARK: - RiveFile Delegate
    
    /// Needed for when resetting to defaults or the RiveViewModel is initialized with a webURL so
    /// we are then able make a RiveModel when the RiveFile is finished downloading
    private struct RiveModelBuffer {
        var artboardName: String?
        var stateMachineName: String?
        var animationName: String?
    }
    
    /// Called by RiveFile when it finishes downloading an asset asynchronously
    public func riveFileDidLoad(_ riveFile: RiveFile) throws {
        riveModel = RiveModel(riveFile: riveFile)
        
        sharedInit(
            artboardName: defaultModel.artboardName,
            stateMachineName: defaultModel.stateMachineName,
            animationName: defaultModel.animationName
        )
    }
    
    // MARK: - RivePlayer Delegate
    
    open func player(playedWithModel riveModel: RiveModel?) { }
    open func player(pausedWithModel riveModel: RiveModel?) { }
    open func player(loopedWithModel riveModel: RiveModel?, type: Int) { }
    open func player(stoppedWithModel riveModel: RiveModel?) { }
    open func player(didAdvanceby seconds: Double, riveModel: RiveModel?) { }
}

/// This makes a SwiftUI digestable view from an `RiveViewModel` and its `RiveView`
public struct RiveViewRepresentable: UIViewRepresentable {
    let viewModel: RiveViewModel
    
    public init(viewModel: RiveViewModel) {
        self.viewModel = viewModel
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RiveView {
        return viewModel.createRiveView()
    }
    
    public func updateUIView(_ view: RiveView, context: UIViewRepresentableContext<RiveViewRepresentable>) {
        viewModel.update(view: view)
    }
    
    public static func dismantleUIView(_ view: RiveView, coordinator: Coordinator) {
        view.stop()
        coordinator.viewModel.deregisterView()
    }
    
    /// Constructs a coordinator for managing updating state
    public func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
    
    public class Coordinator: NSObject {
        public var viewModel: RiveViewModel

        init(viewModel: RiveViewModel) {
            self.viewModel = viewModel
        }
    }
}
