//
//  RFacade.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

open class RFacade {
    private var systemUIKit = RUIKitSubsystem()
    private var systemSwiftUI = RSwiftUISubsystem()
    private var controller: RController
    
    // MARK: Inits
    
    public init(_ viewModel: RViewModel) {
        controller = RController(viewModel)
        //_controller = StateObject(wrappedValue: controller)
    }

    public convenience init(_ asset: String) {
        let model = RModel(asset: asset)
        let viewModel = RViewModel(model)
        self.init(viewModel)
    }
    
    // MARK: Usable Views
    
    public var viewUIKit: UIView {
        let view = RiveViewSwift(
            resource: controller.viewModel.model.assetName!,
            fit: Binding.constant(controller.viewModel.model.fit),
            alignment: Binding.constant(controller.viewModel.model.alignment),
            autoplay: controller.viewModel.model.autoplay,
            artboard: controller.viewModel.model.artboard,
            animation: controller.viewModel.model.animation,
            stateMachine: controller.viewModel.model.stateMachine,
            controller: RiveController()
        )
        return UIHostingController(rootView: view).view
    }
    
    public var viewSwift: ViewSwift {
        return ViewSwift()
    }
    
    // MARK: SwiftUI Util
    
    public struct ViewSwift: View {
        
        public var body: some View {
            RViewSwiftUI(model: RViewModel.riveslider)
        }
    }
}

public protocol RSubsystem {
//    var view: RView { get set }
}

open class RUIKitSubsystem: RSubsystem {
//    public lazy var view: RView
//
//    init(
}

open class RSwiftUISubsystem: RSubsystem {
//    var riveViewSwift: RiveViewSwift
//
//    init() {
//        riveViewSwift = RiveViewSwift(resource: <#T##String#>)
//    }
}

public struct RViewSwiftUI: UIViewRepresentable {
    // TODO: do we want to wrap all of this in @ObservableObject?
    // essentially making our controller, the observableObject
    // the question will be, what properties of this will end up being @Published
    
    let resource: String?
    let httpUrl: String?
    let autoplay: Bool
    let artboard: String?
    let animation: String?
    let stateMachine: String?
    let controller: RController?
    @Binding var fit: Fit
    @Binding var alignment: RiveRuntime.Alignment
    
    // Delegate handlers for loop and play events
    var loopAction: LoopAction = nil
    var playAction: PlaybackAction = nil
    var pauseAction: PlaybackAction = nil
    var inputsAction: InputsAction = nil
    var stopAction: PlaybackAction = nil
    var stateChangeAction: StateChangeAction = nil
    
    
    public init(model: RViewModel, controller: RController? = nil) {
        self.resource = model.model.assetName
        self.httpUrl = nil
        
        self.autoplay = model.model.autoplay
        self.artboard = model.model.artboard
        self.animation = model.model.animation
        self.stateMachine = model.model.stateMachine
        
        self._fit = Binding.constant(model.model.fit)
        self._alignment = Binding.constant(model.model.alignment)
        
        self.controller = controller
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RView {
        var view: RView
        if let resource = resource {
            view = try! RView(
                resource: resource,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboard: artboard,
                animation: animation,
                stateMachine: stateMachine,
                playerDelegate: context.coordinator,
                inputsDelegate: context.coordinator,
                stateChangeDelegate: context.coordinator
            )
        }
        else if let httpUrl = httpUrl {
            view = try! RView(
                httpUrl: httpUrl,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboard: artboard,
                animation: animation,
                stateMachine: stateMachine,
                playerDelegate: context.coordinator,
                inputsDelegate: context.coordinator,
                stateChangeDelegate: context.coordinator
            )
        }
        else {
            view = RView()
        }
        
        controller?.registerView(view)
        return view
    }
    
    public func updateUIView(_ view: RView, context: UIViewRepresentableContext<RViewSwiftUI>) {
        if (fit != view.fit) {
            view.fit = fit
        }
        
        if (alignment != view.alignment) {
            view.alignment = alignment
        }
    }
    
    public static func dismantleUIView(_ view: RView, coordinator: Self.Coordinator) {
        view.stop()
        
        // TODO: is this neccessary
        coordinator.controller?.deregisterView()
    }
    
    // Constructs a coordinator for managing updating state
    public func makeCoordinator() -> Coordinator {
        return Coordinator(
            controller: controller,
            loopAction: loopAction,
            playAction: playAction,
            pauseAction: pauseAction,
            inputsAction: inputsAction,
            stopAction: stopAction,
            stateChangeAction: stateChangeAction
        )
    }
}

// MARK: - Coordinator
extension RViewSwiftUI {
    public class Coordinator: NSObject, RPlayerDelegate, InputsDelegate, StateChangeDelegate {
        public var controller: RController?
        private var loopAction: LoopAction
        private var playAction: PlaybackAction
        private var pauseAction: PlaybackAction
        private var inputsAction: InputsAction
        private var stopAction: PlaybackAction
        private var stateChangeAction: StateChangeAction
        
        init(
            controller: RController?,
            loopAction: LoopAction,
            playAction: PlaybackAction,
            pauseAction: PlaybackAction,
            inputsAction: InputsAction,
            stopAction: PlaybackAction,
            stateChangeAction: StateChangeAction
        ) {
            self.controller = controller
            self.loopAction = loopAction
            self.playAction = playAction
            self.pauseAction = pauseAction
            self.inputsAction = inputsAction
            self.stopAction = stopAction
            self.stateChangeAction = stateChangeAction
        }
        
        public func loop(animation animationName: String, type: Int) {
            loopAction?(animationName, type)
        }
        
        public func play(animation animationName: String, isStateMachine: Bool) {
            playAction?(animationName, isStateMachine)
        }
        
        public func pause(animation animationName: String, isStateMachine: Bool) {
            pauseAction?(animationName, isStateMachine)
        }
        
        public func inputs(_ inputs: [StateMachineInput]) {
            inputsAction?(inputs)
        }
        
        public func stop(animation animationName: String, isStateMachine: Bool) {
            stopAction?(animationName, isStateMachine)
        }
        
        public func stateChange(_ stateMachineName: String, _ stateName: String) {
            stateChangeAction?(stateMachineName, stateName)
        }
    }
}

// MARK: - Old experiements

public struct RiveResource: View {
    @StateObject var controller: NewRiveController
    @State private var touchEvent: RTouchEvent? = nil {
        didSet {
            controller.touchEventFromView = touchEvent
        }
    }

    // MARK: -

    public init(_ riveAsset: RResource) {
        let controller = NewRiveController(riveAsset: Published(initialValue: riveAsset))
        _controller = StateObject(wrappedValue: controller)
    }

    public init(_ resource: String) {
        self.init(RResource(resource: resource))
    }

    // MARK: -

    public var body: some View {
        VStack { }
        RiveViewSwift(resource: controller.model.resourceName,
                      fit: $controller.model.fit,
                      alignment: $controller.model.alignment,
                      autoplay: controller.model.autoplay,
                      artboard: controller.model.artboard,
                      animation: controller.model.animation,
                      stateMachine: controller.model.stateMachine,
                      controller: controller.oldController)
        .onAppear {
            controller.setBindings(touchEvent: $touchEvent)
        }
        .onTapGesture {
            touchEvent = RTouchEvent(type: .touchUp, location: CGPoint.zero)
        }
    }
}

class NewRiveController: ObservableObject {
    @Published var model: RResource
    @Published var oldController = RiveController()
    private var energy: Float = 0
    
    @Binding var touchEventFromView: RTouchEvent? {
        didSet {
            if let touchEvent = touchEventFromView {
                touch(event: touchEvent)
            }
        }
    }
    
    // MARK: -
    
    init(riveAsset: Published<RResource>) {
        _model = riveAsset
        _touchEventFromView = Binding.constant(.none)
    }
    
    // MARK: -
    
    /// Views that are watching for touch events can send them here to be used by the
    /// Rive artboard hit testing
    ///
    /// Seemingly SwiftUI is unable to provide precise touch locations of it's Views so this
    /// will only be used by UIKit implementations for now
    ///
    /// - Parameters:
    ///   - touchLocation: Precise location of the user's touch in its view's coordinate space
    ///   - event: The nature of the touch event
    public func touch(event: RTouchEvent?) {
        print(model.resourceName + " was touched")
        try? oldController.setNumberState(model.stateMachine ?? "", inputName: "Energy", value: energy == 0 ? 100 : 0)
        
        // TODO:
        // Proper way of customizing behavior for touch should be connecting to a delegate which defineds
        // behavior in methods that accept the same arguments as the controller's relevant methods
    }
    
    private func hitResponse(eventName: String) {
        // Hit test response
    }
    
    public func setBindings(touchEvent: Binding<RTouchEvent?>) {
        _touchEventFromView = touchEvent
    }
}
