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
@objc open class RiveViewModel: NSObject, ObservableObject, RiveFileDelegate, RiveStateMachineDelegate, RivePlayerDelegate{
    /// The default layout scale factor that allows for the scale factor to be determined by Rive.
    @objc public static let layoutScaleFactorAutomatic: Double = RiveView.Constants.layoutScaleFactorAutomatic

    // TODO: could be a weak ref, need to look at this in more detail.
    open private(set) var riveView: RiveView?
    private var defaultModel: RiveModelBuffer!

    @objc public init(
        _ model: RiveModel,
        stateMachineName: String?,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
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
    
    @objc public init(
        _ model: RiveModel,
        animationName: String? = nil,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
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
    
    @objc public init(
        fileName: String,
        extension: String = ".riv",
        in bundle: Bundle = .main,
        stateMachineName: String?,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        loadCdn: Bool = true,
        customLoader: LoadAsset? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = try! RiveModel(fileName: fileName, extension: `extension`, in: bundle, loadCdn: loadCdn, customLoader:customLoader)
        sharedInit(artboardName: artboardName, stateMachineName: stateMachineName, animationName: nil)
    }
    
    public init(
        fileName: String,
        extension: String = ".riv",
        in bundle: Bundle = .main,
        animationName: String? = nil,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        preferredFramesPerSecond: Int? = nil,
        loadCdn: Bool = true,
        customLoader: LoadAsset? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = try! RiveModel(fileName: fileName, extension: `extension`, in: bundle, loadCdn: loadCdn, customLoader:customLoader)
        sharedInit(artboardName: artboardName, stateMachineName: nil, animationName: animationName)
    }
    
    @objc public init(
        webURL: String,
        stateMachineName: String?,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
        autoPlay: Bool = true,
        loadCdn: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = RiveModel(webURL: webURL, delegate: self, loadCdn: loadCdn)
        defaultModel = RiveModelBuffer(artboardName: artboardName, stateMachineName: stateMachineName, animationName: nil)
    }
    
    @objc public init(
        webURL: String,
        animationName: String? = nil,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center,
        autoPlay: Bool = true,
        loadCdn: Bool = true,
        artboardName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        super.init()
        riveModel = RiveModel(webURL: webURL, delegate: self, loadCdn: loadCdn)
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
    
    open var fit: RiveFit = .contain {
        didSet { riveView?.fit = fit }
    }
    
    open var alignment: RiveAlignment = .center {
        didSet { riveView?.alignment = alignment }
    }
    
    /// The scale factor to apply when using the `layout` fit. By default, this value is -1, where Rive will determine
    /// the correct scale for your device.To override this default behavior, set this value to a value greater than 0.
    /// - Note: If the scale factor <= 0, nothing will be drawn.
    open var layoutScaleFactor: Double = layoutScaleFactorAutomatic {
        didSet { riveView?.layoutScaleFactor = layoutScaleFactor }
    }
    
    /// Sets whether or not the current Rive view should forward Rive listener touch / click events to any next responders.
    /// When true, touch / click events will be forwarded to any next responder(s).
    /// When false, only the Rive view will handle touch / click events, and will not forward
    /// to any next responder(s). Defaults to `false`, as to preserve pre-existing runtime functionality.
    /// - Note: On iOS, this is handled separately from `isExclusiveTouch`.
    open var forwardsListenerEvents: Bool = false {
        didSet { riveView?.forwardsListenerEvents = forwardsListenerEvents }
    }

    #if os(macOS)
    /// Hints to underlying CADisplayLink in RiveView (if created) the preferred FPS to run at
    /// For more, see: https://developer.apple.com/documentation/quartzcore/cadisplaylink/1648421-preferredframespersecond
    /// - Parameters:
    ///   - preferredFramesPerSecond: Integer number of seconds to set preferred FPS at
    @available(macOS 14, *)
    public func setPreferredFramesPerSecond(preferredFramesPerSecond: Int) {
        riveView?.setPreferredFramesPerSecond(preferredFramesPerSecond: preferredFramesPerSecond)
    }
    
    /// Hints to underlying CADisplayLink in RiveView (if created) the preferred frame rate range
    /// For more, see: https://developer.apple.com/documentation/quartzcore/cadisplaylink/3875343-preferredframeraterange
    /// - Parameters:
    ///   - preferredFrameRateRange: Frame rate range to set
    @available(macOS 14, *)
    public func setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange) {
        riveView?.setPreferredFrameRateRange(preferredFrameRateRange: preferredFrameRateRange)
    }
    #else
    /// Hints to underlying CADisplayLink in RiveView (if created) the preferred FPS to run at
    /// For more, see: https://developer.apple.com/documentation/quartzcore/cadisplaylink/1648421-preferredframespersecond
    /// - Parameters:
    ///   - preferredFramesPerSecond: Integer number of seconds to set preferred FPS at
    public func setPreferredFramesPerSecond(preferredFramesPerSecond: Int) {
        riveView?.setPreferredFramesPerSecond(preferredFramesPerSecond: preferredFramesPerSecond)
    }
    
    /// Hints to underlying CADisplayLink in RiveView (if created) the preferred frame rate range
    /// For more, see: https://developer.apple.com/documentation/quartzcore/cadisplaylink/3875343-preferredframeraterange
    /// - Parameters:
    ///   - preferredFrameRateRange: Frame rate range to set
    @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
    public func setPreferredFrameRateRange(preferredFrameRateRange: CAFrameRateRange) {
        riveView?.setPreferredFrameRateRange(preferredFrameRateRange: preferredFrameRateRange)
    }
    #endif
    
    /// Starts the active Animation or StateMachine from it's last position. It will start
    /// from the beginning if the active Animation has ended or a new one is provided.
    /// - Parameters:
    ///   - animationName: The name of a new Animation to play on the current Artboard
    ///   - loop: The loop mode for the active Animation
    @objc open func play(animationName: String? = nil, loop: RiveLoop = .autoLoop, direction: RiveDirection = .autoDirection) {
        if let name = animationName {
            try! riveModel?.setAnimation(name)
        }
        
        if let animation = riveModel?.animation {
            if loop != .autoLoop {
                animation.loop(Int32(loop.rawValue))
            }
            
            if direction == .forwards {
                animation.direction(1)
            } else if direction == .backwards {
                animation.direction(-1)
            }
            
            if animation.hasEnded() {
                // Restarts Animation from beginning
                animation.setTime(0)
            }
        }
        
        // We're not checking if a StateMachine is "ended" or "ExitState"
        // But we may want to in the future to enable restarting it by playing again
        RiveLogger.log(viewModel: self, event: .play)
        riveView?.play()
    }
    
    /// Halts the active Animation or StateMachine and will resume from it's current position when next played
    @objc open func pause() {
        RiveLogger.log(viewModel: self, event: .pause)
        riveView?.pause()
    }
    
    /// Halts the active Animation or StateMachine and sets it at its starting position
    @objc open func stop() {
        RiveLogger.log(viewModel: self, event: .stop)
        resetCurrentModel()
        riveView?.stop()
    }
    
    /// Sets the active Animation or StateMachine back to their starting position
    @objc open func reset() {
        RiveLogger.log(viewModel: self, event: .reset)
        resetCurrentModel()
        riveView?.reset()
    }
    
    // MARK: - RiveModel
    
    /// Instantiates elements in the model needed to play in a `RiveView`
    @objc open func configureModel(artboardName: String? = nil, stateMachineName: String? = nil, animationName: String? = nil) throws {
        guard let model = riveModel else {
            let errorMessage = "Cannot configure nil RiveModel"
            RiveLogger.log(viewModel: self, event: .fatalError(errorMessage))
            fatalError(errorMessage)
        }

        model.animation = nil
        model.stateMachine = nil
        
        if let name = artboardName {
            try model.setArtboard(name)
        } else {
            // Keep current Artboard if there is one
            if model.artboard == nil {
                // Set default Artboard if not
                try model.setArtboard()
            }
        }
        
        if let name = stateMachineName {
            try model.setStateMachine(name)
        }
        else if let name = animationName {
            try model.setAnimation(name)
        }
        
        // Find defaults
        else {
            // Attempts to set a default StateMachine first
            if ((try? model.setStateMachine()) == nil) {
                // If it fails, attempts a default Animation
                try model.setAnimation()
            }
        }
    }
    
    /// Puts the active Animation or StateMachine back to their starting position
    private func resetCurrentModel() {
        guard let model = riveModel else {
            let errorMessage = "Current model is nil"
            RiveLogger.log(viewModel: self, event: .fatalError(errorMessage))
            fatalError(errorMessage)
        }
        try! configureModel(
            artboardName: model.artboard.name(),
            stateMachineName: model.stateMachine?.name(),
            animationName: model.animation?.name()
        )
    }
    
    /// Sets the Artboard, StateMachine or Animation back to the first one given to the RiveViewModel
    @objc open func resetToDefaultModel() {
        try! configureModel(
            artboardName: defaultModel.artboardName,
            stateMachineName: defaultModel.stateMachineName,
            animationName: defaultModel.animationName
        )
    }
    
    
    /// Provide the active StateMachine a `Trigger` input
    /// - Parameter inputName: The name of a `Trigger` input on the active StateMachine
    @objc open func triggerInput(_ inputName: String) {
        RiveLogger.log(viewModel: self, event: .triggerInput(inputName, nil))
        riveModel?.stateMachine?.getTrigger(inputName).fire()
        play()
    }
    
    /// Provide the active StateMachine a `Boolean` input
    /// - Parameters:
    ///   - inputName: The name of a `Boolean` input on the active StateMachine
    ///   - value: A Bool value for the input
    @objc(setBooleanInput::) open func setInput(_ inputName: String, value: Bool) {
        RiveLogger.log(viewModel: self, event: .booleanInput(inputName, nil, value))
        riveModel?.stateMachine?.getBool(inputName).setValue(value)
        play()
    }

    /// Returns the current boolean input by name. Get its value by calling `.value` on the returned object.
    /// - Parameter name: The name of the input
    /// - Returns: The boolean input if it exists. Returns `nil` if the input cannot be found.
    @objc open func boolInput(named name: String) -> RiveSMIBool?
    {
        guard let input = riveModel?.stateMachine?.getBool(name) else {
            RiveLogger.log(viewModel: self, event: .error("Cannot find bool input named \(name)"))
            return nil
        }
        return input
    }

    /// Provide the active StateMachine a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Float value for the input.
    @objc(setFloatInput::) open func setInput(_ inputName: String, value: Float) {
        RiveLogger.log(viewModel: self, event: .floatInput(inputName, nil, value))
        riveModel?.stateMachine?.getNumber(inputName).setValue(value)
        play()
    }

    /// Provide the active StateMachine a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Double value for the input
    @objc(setDoubleInput::) open func setInput(_ inputName: String, value: Double) {
        RiveLogger.log(viewModel: self, event: .doubleInput(inputName, nil, value))
        setInput(inputName, value: Float(value))
    }

    /// Returns the current number input by name. Get its value by calling `.value` on the returned object.
    /// - Parameter name: The name of the input
    /// - Returns: The number input if it exists. Returns `nil` if the input cannot be found.
    @objc open func numberInput(named name: String) -> RiveSMINumber?
    {
        guard let input = riveModel?.stateMachine?.getNumber(name) else {
            RiveLogger.log(viewModel: self, event: .error("Cannot find number input named \(name)"))
            return nil
        }
        return input
    }

    /// Provide the specified nested Artboard with a `Trigger` input
    /// - Parameters:
    ///   - inputName: The name of a `Trigger` input on the active StateMachine
    ///   - path: A String representing the path to the nested artboard delimited by "/" (ie. "Nested" or "Level1/Level2/Level3")
    open func triggerInput(_ inputName: String, path: String) {
        RiveLogger.log(viewModel: self, event: .triggerInput(inputName, path))
        riveModel?.artboard?.getTrigger(inputName, path: path).fire()
        play()
    }
    
    /// Provide the specified nested Artboard with a `Boolean` input
    /// - Parameters:
    ///   - inputName: The name of a `Boolean` input on the active StateMachine
    ///   - value: A Bool value for the input
    ///   - path: A String representing the path to the nested artboard delimited by "/" (ie. "Nested" or "Level1/Level2/Level3")
    open func setInput(_ inputName: String, value: Bool, path: String) {
        RiveLogger.log(viewModel: self, event: .booleanInput(inputName, path, value))
        riveModel?.artboard?.getBool(inputName, path: path).setValue(value)
        play()
    }
    
    /// Provide the specified nested Artboard with a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Float value for the input
    ///   - path: A String representing the path to the nested artboard delimited by "/" (ie. "Nested" or "Level1/Level2/Level3")
    open func setInput(_ inputName: String, value: Float, path: String) {
        RiveLogger.log(viewModel: self, event: .floatInput(inputName, path, value))
        riveModel?.artboard?.getNumber(inputName, path: path).setValue(value);
        play()
    }
    
    /// Provide the specified nested Artboard with a `Number` input
    /// - Parameters:
    ///   - inputName: The name of a `Number` input on the active StateMachine
    ///   - value: A Double value for the input
    ///   - path: A String representing the path to the nested artboard delimited by "/" (ie. "Nested" or "Level1/Level2/Level3")
    open func setInput(_ inputName: String, value: Double, path: String) {
        RiveLogger.log(viewModel: self, event: .doubleInput(inputName, path, value))
        setInput(inputName, value: Float(value), path: path)
    }

#if WITH_RIVE_TEXT
    /// Get a text value from a specified text run
    /// - Parameters:
    ///   - textRunName: The name of a `Text Run` on the active Artboard
    /// - Returns: String text value of the specified text run if applicable
    @objc open func getTextRunValue(_ textRunName: String) -> String? {
        if let textRun = riveModel?.artboard?.textRun(textRunName) {
            return textRun.text()
        }
        return nil
    }

    /// Get a text value from a specified text run
    /// - Parameters:
    ///   - textRunName: The name of a `Text Run` on the active Artboard
    ///   - path: The path to the nested text run.
    /// - Returns: String text value of the specified text run if applicable
    @objc open func getTextRunValue(_ textRunName: String, path: String) -> String? {
        if let textRun = riveModel?.artboard?.textRun(textRunName, path: path) {
            return textRun.text()
        }
        return nil
    }

    /// Set a text value for a specified text run
    /// - Parameters:
    ///   - textRunName: The name of a `Text Run` on the active Artboard
    ///   - textValue: A String value for the text run
    @objc open func setTextRunValue(_ textRunName: String, textValue: String) throws {
        if let textRun = riveModel?.artboard?.textRun(textRunName) {
            RiveLogger.log(viewModel: self, event: .textRun(textRunName, nil, textValue))
            textRun.setText(textValue)

            if isPlaying == false {
                riveView?.advance(delta: 0)
            }
        } else {
            let errorMessage = "Could not set text value on text run: \(textRunName) as the text run could not be found from the active artboard"
            RiveLogger.log(viewModel: self, event: .error(errorMessage))
            throw RiveError.textValueRunError(errorMessage)
        }
    }

    /// Set a text value for a specified text run
    /// - Parameters:
    ///   - textRunName: The name of a `Text Run` on the active Artboard
    ///   - path: The path to the nested text run.
    ///   - textValue: A String value for the text run
    /// - Note: If the specified path is empty, the parent artboard will be used to find the text run.
    @objc open func setTextRunValue(_ textRunName: String, path: String, textValue: String) throws {
        if let textRun = riveModel?.artboard?.textRun(textRunName, path: path) {
            RiveLogger.log(viewModel: self, event: .textRun(textRunName, path, textValue))
            textRun.setText(textValue)

            if isPlaying == false {
                riveView?.advance(delta: 0)
            }
        } else {
            let errorMessage = "Could not set text value on text run: \(textRunName) as the text run could not be found from the active artboard"
            RiveLogger.log(viewModel: self, event: .error(errorMessage))
            throw RiveError.textValueRunError(errorMessage)
        }
    }
#endif

    // TODO: Replace this with a more robust structure of the file's contents
    @objc open func artboardNames() -> [String] {
        return riveModel?.riveFile.artboardNames() ?? []
    }
    
    // MARK: - SwiftUI Helpers
    
    /// Makes a new `RiveView` for the instance property with data from model which will
    /// replace any previous `RiveView`. This is called when first drawing a `RiveViewRepresentable`.
    /// - Returns: Reference to the new view that the `RiveViewModel` will be maintaining
    @objc open func createRiveView() -> RiveView {
        let view: RiveView
        
        if let model = riveModel {
            view = RiveView(model: model, autoPlay: autoPlay)
        } else {
            view = RiveView()
        }
        
        registerView(view)
        
        return view
    }
    
    open func setRiveView(view:RiveView)
    {
        registerView(view)
    }
    
    /// Gives updated layout values to the provided `RiveView`. This is called in
    /// the process of re-displaying `RiveViewRepresentable`.
    /// - Parameter view: the `RiveView` that will be updated
    @objc open func update(view: RiveView) {
        view.fit = fit
        view.alignment = alignment
        view.layoutScaleFactor = layoutScaleFactor
        view.forwardsListenerEvents = forwardsListenerEvents
    }
    
    /// Assigns the provided `RiveView` to the riveView property. This is called when
    /// creating a `RiveViewRepresentable` in the `.view()` method for SwiftUI and when
    /// adding to the view hierarchy with `.createRiveView()` in UIKit.
    ///
    /// - Parameter view: the `RiveView` that this `RiveViewModel` will maintain
    fileprivate func registerView(_ view: RiveView) {
        riveView = view
        riveView!.playerDelegate = self
        riveView!.stateMachineDelegate = self
        riveView!.fit = fit
        riveView!.alignment = alignment
        riveView!.layoutScaleFactor = layoutScaleFactor
        riveView!.forwardsListenerEvents = forwardsListenerEvents
    }
    
    /// Stops maintaining a connection to any `RiveView`
    open func deregisterView() {
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
    /// - Parameter view: the `RiveView` that this `RiveViewModel` will maintain
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
    @objc open func riveFileDidLoad(_ riveFile: RiveFile) throws {
        riveModel = RiveModel(riveFile: riveFile)
        
        sharedInit(
            artboardName: defaultModel.artboardName,
            stateMachineName: defaultModel.stateMachineName,
            animationName: defaultModel.animationName
        )
    }
    
    // MARK: - RivePlayer Delegate
    
    @objc open func player(playedWithModel riveModel: RiveModel?) { }
    @objc open func player(pausedWithModel riveModel: RiveModel?) { }
    @objc open func player(loopedWithModel riveModel: RiveModel?, type: Int) { }
    @objc open func player(stoppedWithModel riveModel: RiveModel?) { }
    @objc open func player(didAdvanceby seconds: Double, riveModel: RiveModel?) { }
    
    enum RiveError: Error {
        case textValueRunError(_ message: String)
    }
}

#if os(iOS) || os(visionOS) || os(tvOS)
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
            if (view == coordinator.viewModel.riveView) {
                coordinator.viewModel.deregisterView()
            }
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
#else
    public struct RiveViewRepresentable: NSViewRepresentable {
        let viewModel: RiveViewModel

        public init(viewModel: RiveViewModel) {
            self.viewModel = viewModel
        }

        /// Constructs the view
        public func makeNSView(context: Context) -> RiveView {
            return viewModel.createRiveView()
        }

        public func updateNSView(_ view: RiveView, context: NSViewRepresentableContext<RiveViewRepresentable>) {
            viewModel.update(view: view)
        }

        public static func dismantleNSView(_ view: RiveView, coordinator: Coordinator) {
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
#endif
