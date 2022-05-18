//
//  RiveViewModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import Combine

open class RiveViewModel: NSObject, ObservableObject, RiveFileDelegate, RiveStateMachineDelegate, RivePlayerDelegate {
    open private(set) var riveView: RiveView?
    private var defaultModel: RiveModelBuffer!
    
    public init(
        _ model: RiveModel,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        self.riveModel = model
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        
        super.init()
        
        try! configureModel(artboardName: artboardName, stateMachineName: stateMachineName, animationName: animationName)
    }
    
    public init(
        fileName: String,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        riveModel = try! RiveModel(fileName: fileName)
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        
        super.init()
        
        try! configureModel(artboardName: artboardName, stateMachineName: stateMachineName, animationName: animationName)
    }
    
    public init(
        webURL: String,
        stateMachineName: String? = nil,
        fit: RiveRuntime.Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoPlay: Bool = true,
        artboardName: String? = nil,
        animationName: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.autoPlay = autoPlay
        
        super.init()
        
        riveModel = RiveModel(webURL: webURL, delegate: self)
        defaultModel = RiveModelBuffer(artboardName: artboardName, stateMachineName: stateMachineName, animationName: animationName)
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
    
    open func play(animationName: String? = nil, loop: Loop? = nil) {
        if let name = animationName {
            try! riveModel?.setAnimation(name)
        }
        if let loop = loop?.rawValue {
            riveModel?.animation?.loop(Int32(loop))
        }
        
        riveView?.play()
    }
    
    open func pause() {
        riveView?.pause()
    }
    
    open func stop() {
        riveView?.stop()
        try! resetModelToDefault()
    }
    
    @available(*, deprecated, renamed: "stop")
    open func reset() {
        stop()
    }
    
    // MARK: - RiveModel
    
    /// Instantiates elements in the model needed to play in a `RiveView`
    private func configureModel(artboardName: String? = nil, stateMachineName: String? = nil, animationName: String? = nil) throws {
        if let name = artboardName {
            try riveModel?.setArtboard(name)
        } else {
            // Keep current Artboard if there is one
            if riveModel?.artboard == nil {
                // Set default Artboard if not
                try riveModel?.setArtboard()
            }
        }
        
        riveModel?.animation = nil
        riveModel?.stateMachine = nil
        
        if let name = stateMachineName {
            try riveModel?.setStateMachine(name)
        }
        else if let name = animationName {
            try riveModel?.setAnimation(name)
        }
        else {
            // Set default Animation
            try riveModel?.setAnimation()
        }
        
        try riveView?.setModel(riveModel!, autoPlay: autoPlay)
        defaultModel = RiveModelBuffer(artboardName: artboardName, stateMachineName: stateMachineName, animationName: animationName)
    }
    
    private func resetModelToDefault() throws {
        try configureModel(
            artboardName: defaultModel.artboardName,
            stateMachineName: defaultModel.stateMachineName,
            animationName: defaultModel.animationName
        )
    }
    
    open func triggerInput(_ inputName: String) throws {
        riveModel?.stateMachine?.getTrigger(inputName)
        play()
    }
    
    open func setInput(_ inputName: String, value: Bool) throws {
        riveModel?.stateMachine?.getBool(inputName).setValue(value)
        play()
    }
    
    open func setInput(_ inputName: String, value: Float) throws {
        riveModel?.stateMachine?.getNumber(inputName).setValue(value)
        play()
    }
    
    open func setInput(_ inputName: String, value: Double) throws {
        riveModel?.stateMachine?.getNumber(inputName).setValue(Float(value))
        play()
    }
    
    // MARK: - SwiftUI Helpers
    
    /// Makes a new `RiveView` for the instance property with data from model which will
    /// replace any previous `RiveView`. This is called when first drawing a `StandardView`.
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
    /// the process of re-displaying `StandardView`.
    /// - Parameter rview: the `RiveView` that will be updated
    @objc open func update(view: RiveView) {
        view.fit = fit
        view.alignment = alignment
    }
    
    /// Assigns the provided `RiveView` to its rview property. This is called when creating a
    /// `StandardView`
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
    open func view() -> some View {
        return StandardView(viewModel: self)
    }
    
    /// A simple View designed to display
    public struct StandardView: View {
        let viewModel: RiveViewModel
        
        init(viewModel: RiveViewModel) {
            self.viewModel = viewModel
        }
        
        public var body: some View {
            RiveViewRepresentable(viewModel: viewModel)
        }
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
        
        try! configureModel(
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
