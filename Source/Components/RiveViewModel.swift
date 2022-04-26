//
//  RiveViewModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import Combine

open class RiveViewModel: ObservableObject, RiveTouchDelegate {
    /// This can be assigned to already emplaced UIViews or RViews within .xib files or storyboards
    public private(set) var rview: RiveView?
    public var inputsAction: InputsAction = nil
    public var stateChangeAction: StateChangeAction = nil
    
    @Published private var model: RiveModel
    private var viewRepresentable: RViewRepresentable?
    
    
    public init(_ model: RiveModel) {
        self.model = model
    }
    
    public convenience init(
        fileName: String,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        let model = RiveModel(
            fileName: fileName,
            stateMachineName: stateMachineName,
            fit: fit,
            alignment: alignment,
            autoplay: autoplay,
            artboardName: artboardName,
            animationName: animationName
        )
        
        self.init(model)
    }
    
    public convenience init(
        webURL: String,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoplay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        let model = RiveModel(
            webURL: webURL,
            stateMachineName: stateMachineName,
            fit: fit,
            alignment: alignment,
            autoplay: autoplay,
            artboardName: artboardName,
            animationName: animationName
        )
        
        self.init(model)
    }
    
    /// This can be added to the body of a SwiftUI `View`
    open func view() -> some View {
        return StandardView(viewModel: self)
    }
}
 
// MARK: - RiveView
extension RiveViewModel {
    // MARK: Lifecycle
    
    /// Makes a new `RiveView` for its rview property with data from model which will
    /// replace any previous `RiveView`. This is called when first drawing a `StandardView`.
    /// - Returns: Reference to the new view that the `RiveViewModel` will be maintaining
    public func createRView() -> RiveView {
        let view: RiveView
        
        if let fileName = fileName {
            view = try! RiveView(
                fileName: fileName,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboardName: artboardName,
                animationName: animationName,
                stateMachineName: stateMachineName
            )
        }
        else if let webURL = webURL {
            view = try! RiveView(
                webURL: webURL,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboardName: artboardName,
                animationName: animationName,
                stateMachineName: stateMachineName
            )
        }
        else {
            view = RiveView()
        }
        
        register(rview: view)
        
        return view
    }
    
    /// Gives updated layout values to the provided `RiveView`. This is called in
    /// the process of re-displaying `StandardView`.
    /// - Parameter rview: the `RiveView` that will be updated
    @objc open func update(rview: RiveView) {
        if (fit != rview.fit) {
            rview.fit = fit
        }
        
        if (alignment != rview.alignment) {
            rview.alignment = alignment
        }
    }
    
    /// This can be used to connect with and configure an `RiveView` that was created elsewhere.
    /// Does not need to be called when updating an already configured `RiveView`. Useful for
    /// attaching views created in a `UIViewController` or Storyboard.
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    @objc open func setView(_ rview: RiveView) {
        register(rview: rview)
        
        var file: RiveFile!
        
        if let fileName = fileName {
            file = try! RiveFile(name: fileName)
        }
        else if let webURL = webURL {
            file = RiveFile(httpUrl: webURL, with: rview)!
        }
        
        try? self.rview!.configure(
            file,
            artboardName: artboardName,
            animationName: animationName,
            stateMachineName: stateMachineName,
            autoPlay: autoplay
        )
    }
    
    /// Assigns the provided `RiveView` to its rview property. This is called when creating a
    /// `StandardView`
    /// - Parameter view: the `Rview` that this `RiveViewModel` will maintain
    internal func register(rview: RiveView) {
        self.rview = rview
        self.rview!.playerDelegate = self
        self.rview!.inputsDelegate = self
        self.rview!.stateChangeDelegate = self
        self.rview!.touchDelegate = self
    }
    
    /// Stops maintaining a connection to any `RiveView`
    internal func deregisterView() {
        rview = nil
    }
    
    // MARK: Controls
    
    public func reset() throws {
        try rview?.reset()
    }
    
    // DELETE THIS: Zach - playingAnimations.insert() is called through this
    public func play(_ loop: Loop = .loopAuto, _ direction: Direction = .directionAuto) throws {
        try rview?.play(loop:loop, direction: direction)
    }
    
    // DELETE THIS: Zach - playingAnimations.insert() is called through this
    public func play(
        animationName: String,
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try rview?.play(
            animationName: animationName,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    
    // DELETE THIS: Zach - playingAnimations.insert() is called through this
    public func play(
        animationNames: [String],
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try rview?.play(
            animationNames: animationNames,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    
    public func pause() {
        rview?.pause()
    }
    
    public func pause(_ animationName: String, _ isStateMachine: Bool = false) {
        rview?.pause(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func pause(_ animationNames: [String], _ isStateMachine: Bool = false) {
        rview?.pause(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    public func stop() {
        rview?.stop()
    }
    
    public func stop(_ animationNames: [String], _ isStateMachine: Bool = false) {
        rview?.stop(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    public func stop(_ animationName: String, _ isStateMachine: Bool = false) {
        rview?.stop(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func triggerInput(_ inputName: String, stateMachineName: String) throws {
        try rview?.fireState(stateMachineName, inputName: inputName)
    }
    
    open func setInput(_ inputName: String, value: Bool, stateMachineName: String? = nil) throws {
        try? setGenericInput(inputName, value: value, stateMachineName: stateMachineName)
    }
    
    open func setInput(_ inputName: String, value: Float, stateMachineName: String? = nil) throws {
        try? setGenericInput(inputName, value: value, stateMachineName: stateMachineName)
    }
    
    open func setInput(_ inputName: String, value: Double, stateMachineName: String? = nil) throws {
        try? setGenericInput(inputName, value: Float(value), stateMachineName: stateMachineName)
    }
    
    private func setGenericInput<Value>(_ inputName: String, value: Value, stateMachineName: String? = nil) throws {
        var smName = ""
        if let name = stateMachineName {
            smName = name
        }
        else if let name = self.stateMachineName {
            smName = name
        }
        
        if value is Float {
            try rview?.setNumberState(smName, inputName: inputName, value: value as! Float)
        }
        else if value is Bool {
            try rview?.setBooleanState(smName, inputName: inputName, value: value as! Bool)
        }
    }
}

// MARK: - RiveModel Communication
extension RiveViewModel {
    public var webURL: String? { model.webURL }
    public var fileName: String? { model.fileName }
    
    public var fit: RiveRuntime.Fit {
        get { model.fit }
        set { model.fit = newValue }
    }
    
    public var alignment: RiveRuntime.Alignment {
        get { model.alignment }
        set { model.alignment = newValue }
    }
    
    public var autoplay: Bool {
        get { model.autoplay }
        set { model.autoplay = newValue }
    }
    
    public var artboardName: String? {
        get { model.artboardName }
        set { model.artboardName = newValue }
    }
    
    public var animationName: String? {
        get { model.animationName }
        set { model.animationName = newValue }
    }
    
    public var stateMachineName: String? {
        get { model.stateMachineName }
        set { model.stateMachineName = newValue }
    }
}

// MARK: - Usable Views
extension RiveViewModel {
    public struct StandardView: View {
        let viewModel: RiveViewModel
        
        // TODO: Remove this
        // Our widgets should not be used as root Views or "controllers"
        // If you need to dismiss our widget wrap it in another View that defines such behavior
        public var dismiss: () -> Void = { }
        
        init(viewModel: RiveViewModel) {
            self.viewModel = viewModel
        }
        
        public var body: some View {
            RViewRepresentable(viewModel: viewModel)
        }
    }
}

// MARK: - RPlayerDelegate
extension RiveViewModel: RivePlayerDelegate {
    public func loop(animation animationName: String, type: Int) {
        //print("Animation: [" + animationName + "] - Looped")
    }
    
    public func play(animation animationName: String, isStateMachine: Bool) {
        //print("Animation: [" + animationName + "] - Played")
    }
    
    public func pause(animation animationName: String, isStateMachine: Bool) {
        //print("Animation: [" + animationName + "] - Paused")
    }
    
    public func stop(animation animationName: String, isStateMachine: Bool) {
        //print("Animation: [" + animationName + "] - Stopped")
    }
}

// MARK: - State Delegates
extension RiveViewModel: RInputDelegate, RStateDelegate {
    public func inputs(_ inputs: [StateMachineInput]) {
        inputsAction?(inputs)
    }
    
    public func stateChange(_ stateMachineName: String, _ stateName: String) {
        stateChangeAction?(stateMachineName, stateName)
    }
}

// MARK: - SwiftUI Utility
/// This makes a SwiftUI digestable view from an `RiveViewModel` and its `RiveView`
public struct RViewRepresentable: UIViewRepresentable {
    let viewModel: RiveViewModel
    
    public init(viewModel: RiveViewModel) {
        self.viewModel = viewModel
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RiveView {
        return viewModel.createRView()
    }
    
    public func updateUIView(_ view: RiveView, context: UIViewRepresentableContext<RViewRepresentable>) {
        viewModel.update(rview: view)
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
