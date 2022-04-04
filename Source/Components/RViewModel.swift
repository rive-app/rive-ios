//
//  RViewModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

open class RViewModel: ObservableObject {
    public var inputsAction: InputsAction = nil
    public var stateChangeAction: StateChangeAction = nil
    @Published public var model: RModel
    
    private(set) var view: RView?
    
    
    public init(_ model: RModel) {
        self.model = model
    }
    
    public convenience init(asset: String) {
        self.init(RModel(assetName: asset))
    }
    
    // MARK: RView
    
    func register(view: RView) {
        self.view = view
        self.view!.playerDelegate = self
    }
    
    func deregisterView() {
        view = nil
    }
    
    public func reset() throws {
        try view?.reset()
    }
    
    public func play(_ loop: Loop = .loopAuto, _ direction: Direction = .directionAuto) throws {
        try view?.play(loop:loop, direction: direction)
    }
    
    public func play(
        animationName: String,
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try view?.play(
            animationName: animationName,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    public func play(
        animationNames: [String],
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        isStateMachine: Bool = false
    ) throws {
        try view?.play(
            animationNames: animationNames,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    
    public func pause() {
        view?.pause()
    }
    
    public func pause(_ animationName: String, _ isStateMachine: Bool = false) {
        view?.pause(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func pause(_ animationNames: [String], _ isStateMachine: Bool = false) {
        view?.pause(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    
    public func stop() {
        view?.stop()
    }
    
    public func stop(_ animationNames: [String], _ isStateMachine: Bool = false) {
        view?.stop(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    
    public func stop(_ animationName: String, _ isStateMachine: Bool = false) {
        view?.stop(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func fireState(_ stateMachineName: String, inputName: String) throws {
        try view?.fireState(stateMachineName, inputName: inputName)
    }
    
    open func setState(boolValue: Bool, stateMachineName: String, inputName: String) throws {
        try view?.setBooleanState(stateMachineName, inputName: inputName, value: boolValue)
    }
    
    open func setState(floatValue: Float, stateMachineName: String, inputName: String) throws {
        try view?.setNumberState(stateMachineName, inputName: inputName, value: floatValue)
    }
    
    // MARK: RModel
    
    public var url: String? { model.url }
    
    public var fileName: String? { model.assetName }
    
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
    
    public var artboard: String? {
        get { model.artboard }
        set { model.artboard = newValue }
    }
    
    public var animation: String? {
        get { model.animation }
        set { model.animation = newValue }
    }
    
    public var stateMachine: String? {
        get { model.stateMachine }
        set { model.stateMachine = newValue }
    }
    
    public var touchedLocation: CGPoint? {
        get { model.touchedLocation }
        set { model.touchedLocation = newValue }
    }
    
    // MARK: Usable Views
    
    /// This can be used as a subview of a UIView
    public var viewUIKit: UIView {
        let view = RViewRepresentable(viewModel: RViewModel.riveslider)
        return UIHostingController(rootView: view).view
    }
    
    /// This can be added to the body of a SwiftUI View
    public var viewSwift: StandardView {
        return StandardView(viewModel: self)
    }
    
    public struct StandardView: View {
        let viewModel: RViewModel
        
        init(viewModel: RViewModel) {
            self.viewModel = viewModel
        }
        
        public var body: some View {
            RViewRepresentable(viewModel: viewModel)
        }
    }
}

// MARK: - RPlayerDelegate
extension RViewModel: RPlayerDelegate {
    public func loop(animation animationName: String, type: Int) {
        print("Animation Looped")
    }
    
    public func play(animation animationName: String, isStateMachine: Bool) {
        print("Animation: " + animationName + " - Played")
    }
    
    public func pause(animation animationName: String, isStateMachine: Bool) {
        print("Animation: " + animationName + " - Paused")
    }
    
    public func stop(animation animationName: String, isStateMachine: Bool) {
        print("Animation: " + animationName + " - Stopped")
    }
}

// MARK: - State Delegates
extension RViewModel: InputsDelegate, StateChangeDelegate {
    public func inputs(_ inputs: [StateMachineInput]) {
        inputsAction?(inputs)
    }
    
    public func stateChange(_ stateMachineName: String, _ stateName: String) {
        stateChangeAction?(stateMachineName, stateName)
    }
}


// MARK: - Test Data
extension RViewModel {
    public static var riveslider: RViewModel {
        let model = RModel(assetName: "riveslider7", stateMachine: "Slide")
        return RViewModel(model)
    }
}


public struct RViewRepresentable: UIViewRepresentable {
    let viewModel: RViewModel
    
    public init(viewModel: RViewModel) {
        self.viewModel = viewModel
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RView {
        var view: RView
        
        if let resource = viewModel.fileName {
            view = try! RView(
                resource: resource,
                fit: viewModel.fit,
                alignment: viewModel.alignment,
                autoplay: viewModel.autoplay,
                artboard: viewModel.artboard,
                animation: viewModel.animation,
                stateMachine: viewModel.stateMachine
            )
        }
        else if let httpUrl = viewModel.url {
            view = try! RView(
                httpUrl: httpUrl,
                fit: viewModel.fit,
                alignment: viewModel.alignment,
                autoplay: viewModel.autoplay,
                artboard: viewModel.artboard,
                animation: viewModel.animation,
                stateMachine: viewModel.stateMachine
            )
        }
        else {
            view = RView()
        }
        
        viewModel.register(view:view)
        return view
    }
    
    public func updateUIView(_ view: RView, context: UIViewRepresentableContext<RViewRepresentable>) {
        if (viewModel.fit != view.fit) {
            view.fit = viewModel.fit
        }
        
        if (viewModel.alignment != view.alignment) {
            view.alignment = viewModel.alignment
        }
    }
    
    public static func dismantleUIView(_ view: RView, coordinator: Self.Coordinator) {
        view.stop()
        
        // TODO: is this neccessary
        coordinator.viewModel.deregisterView()
    }
    
    // Constructs a coordinator for managing updating state
    public func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
}

// MARK: - Coordinator
extension RViewRepresentable {
    public class Coordinator: NSObject {
        public var viewModel: RViewModel

        init(viewModel: RViewModel) {
            self.viewModel = viewModel
        }
    }
}
