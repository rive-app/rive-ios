//
//  RController.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/17/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

// MARK: Test
// This is an experiment for testing the plausability of subclassing something like the
// controller, viewmodel or facade in the new framework
open class RController: RPlayerDelegate {
    var view: RView?
    var viewModel: RViewModel
    private var playerDelegates: [RPlayerDelegate?] = []
    
    init(_ viewModel: RViewModel) {
        self.viewModel = viewModel
        
        self.view?.playerDelegate = self
    }
    
    // MARK: RController
    
    func registerView(_ view: RView) {
        self.view = view
    }
    
    func deregisterView() {
        view = nil
    }
    
    // MARK: - RPlayerDelegate
    
    public func loop(animation animationName: String, type: Int) {
        print("Animation Looped")
    }
    
    public func play(animation animationName: String, isStateMachine: Bool) {
        print("Animation Played")
    }
    
    public func pause(animation animationName: String, isStateMachine: Bool) {
        print("Animation Paused")
    }
    
    public func stop(animation animationName: String, isStateMachine: Bool) {
        print("Animation Stopped")
    }
}
// MARK: End Test


















//struct floop<Content:View>: View {
//    let view: ()->Content
//
//    init(@ViewBuilder content: @escaping ()->Content) {
//        view = content
//    }
//
//    var body: some View {
//        view()
//    }
//}

public class RResource: ObservableObject {
    public let resourceName: String
    @Binding public var fit: RiveRuntime.Fit
    @Binding public var alignment: RiveRuntime.Alignment
    public var autoplay: Bool
    public var artboard: String?
    public var animation: String?
    public var stateMachine: String?
    public var touchedLocation: CGPoint?
    
    public init(
        resource: String,
        fit: Binding<RiveRuntime.Fit> = .constant(.fitFill),
        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
        autoplay: Bool = true,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        touchedLocation: CGPoint? = nil
    ) {
        self.resourceName = resource
        _fit = fit
        _alignment = alignment
        self.autoplay = autoplay
        self.artboard = artboard
        self.animation = animation
        self.stateMachine = stateMachine
        self.touchedLocation = touchedLocation
    }
}

public enum RPlayerEventType: String {
    case played = "Played"
    case stopped = "Stopped"
    case paused = "Paused"
    case looped = "Looped"
    case ended = "Ended"
}

public enum RTouchEventType {
    case none
    case touchDown
    case touchUp
    case touchMove
    case touchCancelled
}

public struct RTouchEvent {
    public let type: RTouchEventType
    public let location: CGPoint
//    public let coordinateSpace: UICoordinateSpace
    public let timestamp = Date()
    
    public init(type: RTouchEventType, location: CGPoint) {
        self.type = type
        self.location = location
    }
}

//
//
//// ok we need to structure this a different way. as we're going to leak memory
//public class NewRiveController {
//    public var riveAsset: RiveAsset
//    
//    public init(){}
//    
//    var riveView:RiveView? = nil
//    
//    public func registerView(
//        _ view: RiveView
//    ) {
//        riveView = view
//    }
//    
//    public func deregisterView(){
//        riveView = nil
//    }
//    
//    public func reset() throws {
//        try riveView?.reset()
//    }
//    
//    public func play(
//        _ loop: Loop = .loopAuto,
//        _ direction: Direction = .directionAuto
//    ) throws {
//        try riveView?.play(loop:loop, direction: direction)
//    }
//    
//    public func play(
//        _ animationName: String,
//        _ loop: Loop = .loopAuto,
//        _ direction: Direction = .directionAuto,
//        _ isStateMachine: Bool = false
//    ) throws {
//        try riveView?.play(
//            animationName: animationName,
//            loop: loop,
//            direction: direction,
//            isStateMachine: isStateMachine
//        )
//    }
//    public func play(
//        _ animationNames: [String],
//        _ loop: Loop = .loopAuto,
//        _ direction: Direction = .directionAuto,
//        _ isStateMachine: Bool = false
//    ) throws {
//        try riveView?.play(
//            animationNames: animationNames,
//            loop: loop,
//            direction: direction,
//            isStateMachine: isStateMachine
//        )
//    }
//    
//    public func pause() {
//        riveView?.pause()
//    }
//    
//    public func pause(
//        _ animationName: String,
//        _ isStateMachine: Bool = false
//    ) {
//        riveView?.pause(
//            animationName: animationName,
//            isStateMachine: isStateMachine
//        )
//    }
//    
//    public func pause(
//        _ animationNames: [String],
//        _ isStateMachine: Bool = false
//    ) {
//        riveView?.pause(
//            animationNames: animationNames,
//            isStateMachine: isStateMachine
//        )
//    }
//    
//    
//    public func stop() {
//        riveView?.stop()
//    }
//    
//    public func stop(
//        _ animationNames: [String],
//        _ isStateMachine: Bool = false
//    ) {
//        riveView?.stop(
//            animationNames: animationNames,
//            isStateMachine: isStateMachine
//        )
//    }
//    
//    
//    public func stop(
//        _ animationName: String,
//        _ isStateMachine: Bool = false
//    ) {
//        riveView?.stop(
//            animationName: animationName,
//            isStateMachine: isStateMachine
//        )
//    }
//    
//    public func fireState(_ stateMachineName: String, inputName: String) throws {
//        try riveView?.fireState(stateMachineName, inputName: inputName)
//    }
//    
//    open func setBooleanState(_ stateMachineName: String, inputName: String, value: Bool) throws {
//        try riveView?.setBooleanState(stateMachineName, inputName: inputName, value: value)
//    }
//    
//    open func setNumberState(_ stateMachineName: String, inputName: String, value: Float) throws {
//        try riveView?.setNumberState(stateMachineName, inputName: inputName, value: value)
//    }
//    
//}
//
//enum RiveViewError: Error {
//    case noResourceOrHttpUrl
//}
//
////  MARK: RiveViewSwift is highly experimental and subject to change without major version changes
//@available(iOS 13.0, *)
//public struct RiveViewSwift: UIViewRepresentable {
//    // TODO: do we want to wrap all of this in @ObservableObject?
//    // essentially making our controller, the observableObject
//    // the question will be, what properties of this will end up being @Published
//    
//    let resourceName: String?
//    let httpUrl: String?
//    let autoplay: Bool
//    let artboard: String?
//    let animation: String?
//    let stateMachine: String?
//    let controller: RiveController?
//    @Binding var fit: Fit
//    @Binding var alignment: RiveRuntime.Alignment
//    
//    // Delegate handlers for loop and play events
//    var loopAction: LoopAction = nil
//    var playAction: PlaybackAction = nil
//    var pauseAction: PlaybackAction = nil
//    var inputsAction: InputsAction = nil
//    var stopAction: PlaybackAction = nil
//    var stateChangeAction: StateChangeAction = nil
//    
//    
//    
//    public init(
//        resource: String,
//        fit: Binding<Fit> = .constant(.fitContain),
//        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
//        autoplay: Bool = true,
//        artboard: String? = nil,
//        animation: String? = nil,
//        stateMachine: String? = nil,
//        controller: RiveController? = nil
//    ) {
//        self.resource = resource
//        self.httpUrl = nil
//        
//        self.autoplay = autoplay
//        self.artboard = artboard
//        self.animation = animation
//        self.stateMachine = stateMachine
//        
//        self._fit = fit
//        self._alignment = alignment
//        
//        self.controller = controller
//    }
//    
//    public init(
//        httpUrl: String,
//        fit: Binding<Fit> = .constant(.fitContain),
//        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
//        autoplay: Bool = true,
//        artboard: String? = nil,
//        animation: String? = nil,
//        stateMachine: String? = nil,
//        controller: RiveController? = nil
//    ) {
//        self.resource = nil
//        self.httpUrl = httpUrl
//        
//        self.autoplay = autoplay
//        self.artboard = artboard
//        self.animation = animation
//        self.stateMachine = stateMachine
//        
//        self._fit = fit
//        self._alignment = alignment
//        
//        self.controller = controller
//    }
//    
//    /// Constructs the view
//    public func makeUIView(context: Context) -> RiveView {
//        var riveView: RiveView
//        if let resource = resource {
//            riveView = try! RiveView(
//                resource: resource,
//                fit: fit,
//                alignment: alignment,
//                autoplay: autoplay,
//                artboard: artboard,
//                animation: animation,
//                stateMachine: stateMachine,
//                loopDelegate: context.coordinator,
//                playDelegate: context.coordinator,
//                pauseDelegate: context.coordinator,
//                stopDelegate: context.coordinator,
//                inputsDelegate: context.coordinator,
//                stateChangeDelegate: context.coordinator
//            )
//        }
//        else if let httpUrl = httpUrl {
//            riveView = try! RiveView(
//                httpUrl: httpUrl,
//                fit: fit,
//                alignment: alignment,
//                autoplay: autoplay,
//                artboard: artboard,
//                animation: animation,
//                stateMachine: stateMachine,
//                loopDelegate: context.coordinator,
//                playDelegate: context.coordinator,
//                pauseDelegate: context.coordinator,
//                stopDelegate: context.coordinator,
//                inputsDelegate: context.coordinator,
//                stateChangeDelegate: context.coordinator
//            )
//        }
//        else {
//            riveView = RiveView()
//        }
//        
//        controller?.registerView(riveView)
//        return riveView
//    }
//    
//    public func updateUIView(
//        _ riveView: RiveView,
//        context: UIViewRepresentableContext<RiveViewSwift>
//    ) {
//        if (fit != riveView.fit){
//            riveView.fit = fit
//        }
//        if (alignment != riveView.alignment) {
//            riveView.alignment = alignment
//        }
//    }
//    
//    public static func dismantleUIView(
//        _ riveView: RiveView,
//        coordinator: Self.Coordinator
//    ) {
//        riveView.stop()
//        
//        // TODO: is this neccessary
//        coordinator.controller?.deregisterView()
//    }
//    
//    // Constructs a coordinator for managing updating state
//    public func makeCoordinator() -> Coordinator {
//        Coordinator(
//            controller: controller,
//            loopAction: loopAction,
//            playAction: playAction,
//            pauseAction: pauseAction,
//            inputsAction: inputsAction,
//            stopAction: stopAction,
//            stateChangeAction: stateChangeAction
//        )
//    }
//    
//}
//
//@available(iOS 13.0, *)
//extension RiveViewSwift {
//    
//    // MARK: - Coordinator
//    
//    // Coordinator between RiveView and UIRiveView
//    public class Coordinator: NSObject, LoopDelegate, PlayDelegate, PauseDelegate, InputsDelegate, StopDelegate, StateChangeDelegate {
//        
//        public var controller: RiveController?
//        private var loopAction: LoopAction
//        private var playAction: PlaybackAction
//        private var pauseAction: PlaybackAction
//        private var inputsAction: InputsAction
//        private var stopAction: PlaybackAction
//        private var stateChangeAction: StateChangeAction
//        
//        init(
//            controller: RiveController?,
//            loopAction: LoopAction,
//            playAction: PlaybackAction,
//            pauseAction: PlaybackAction,
//            inputsAction: InputsAction,
//            stopAction: PlaybackAction,
//            stateChangeAction: StateChangeAction
//        ) {
//            self.controller = controller
//            self.loopAction = loopAction
//            self.playAction = playAction
//            self.pauseAction = pauseAction
//            self.inputsAction = inputsAction
//            self.stopAction = stopAction
//            self.stateChangeAction = stateChangeAction
//            
//        }
//        
//        public func loop(_ animationName: String, type: Int) {
//            loopAction?(animationName, type)
//        }
//        
//        public func play(_ animationName: String, isStateMachine: Bool) {
//            playAction?(animationName, isStateMachine)
//        }
//        
//        public func pause(_ animationName: String, isStateMachine: Bool) {
//            pauseAction?(animationName, isStateMachine)
//        }
//        
//        public func inputs(_ inputs: [StateMachineInput]) {
//            inputsAction?(inputs)
//        }
//        
//        public func stop(_ animationName: String, isStateMachine: Bool) {
//            stopAction?(animationName, isStateMachine)
//        }
//        
//        public func stateChange(_ stateMachineName: String, _ stateName: String) {
//            stateChangeAction?(stateMachineName, stateName)
//        }
//    }
//}
