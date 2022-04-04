//
//  RController.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/17/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI


open class RController {
    var view: RView?
    var viewModel: RViewModel
    
    // Delegate handlers for loop and play events
//    var loopAction: LoopAction = nil
//    var playAction: PlaybackAction = nil
//    var pauseAction: PlaybackAction = nil
    var inputsAction: InputsAction = nil
//    var stopAction: PlaybackAction = nil
    var stateChangeAction: StateChangeAction = nil
//
//    private var playerDelegates: [RPlayerDelegate?] = []
    
    
    init(_ viewModel: RViewModel) {
        self.viewModel = viewModel
    }
    
//    init(_ model: RModel) {
//
//    }
//    init(_ view: RView) {
//
//    }
    
    
    func register(view: RView) {
        // This should happen inside RViewModel
        self.view = view
        self.view!.playerDelegate = self
    }
    
    func deregisterView() {
        view = nil
    }
    
    func register(viewModel: RViewModel) {
        self.viewModel = viewModel
    }
    
    func updateView(withViewModel viewModel: RViewModel) {
//        view.conf
    }
}

// MARK: - RPlayerDelegate
extension RController: RPlayerDelegate {
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
extension RController: InputsDelegate, StateChangeDelegate {
    public func inputs(_ inputs: [StateMachineInput]) {
        inputsAction?(inputs)
    }
    
    public func stateChange(_ stateMachineName: String, _ stateName: String) {
        stateChangeAction?(stateMachineName, stateName)
    }
}

















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
    case touchDown
    case touchMove
    case touchUp
    //case touchCancelled
}

public struct RTouchEvent {
    public let type: RTouchEventType
    public let location: CGPoint
    public let index: Int
    public let timestamp = Date()
}

public protocol RTouchDelegate {
    func received(touchEvent: RTouchEvent)
}
