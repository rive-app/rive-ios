//
//  RFacade.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

//open class RFacade {
//    private var controller: RController
//    
//    // MARK: Inits
//    
//    public init(_ viewModel: RViewModel) {
//        if let controller = viewModel.controller {
//            self.controller = controller
//        } else {
//            controller = RController(viewModel)
//            viewModel.controller = controller
//        }
//    }
//
//    public convenience init(_ asset: String) {
//        let model = RModel(assetName: asset)
//        let viewModel = RViewModel(model)
//        self.init(viewModel)
//    }
//    
//    // MARK: - Binding
//    
//    public func register(viewModel: RViewModel) {
//        self.controller.register(viewModel: viewModel)
//    }
//    
//    // MARK: Usable Views
//    
//    public var viewUIKit: UIView {
//        let view = RViewSwiftUI(viewModel: RViewModel.riveslider)
//        
////        RiveViewSwift(
////            resource: controller.viewModel.model.assetName!,
////            fit: Binding.constant(controller.viewModel.model.fit),
////            alignment: Binding.constant(controller.viewModel.model.alignment),
////            autoplay: controller.viewModel.model.autoplay,
////            artboard: controller.viewModel.model.artboard,
////            animation: controller.viewModel.model.animation,
////            stateMachine: controller.viewModel.model.stateMachine,
////            controller: RiveController()
////        )
//        return UIHostingController(rootView: view).view
//        
//        // Ideal flow: controller.getView() - (Inside RController's getView() is viewModel.getView() )
//    }
//    
//    public var viewSwift: ViewSwift {
//        return ViewSwift()
//        
//        // Ideal flow: controller.getView() - (Inside RController's getView() is viewModel.getView() )
//    }
//    
//    // MARK: SwiftUI Util
//    
//    // TODO: Try to make a View that  accepts a closure with the contents being UIHostingViewController
//    
//    public struct ViewSwift: View {
//        
//        public var body: some View {
//            RViewSwiftUI(viewModel: RViewModel.riveslider)
//        }
//    }
//}
//
//public struct RViewSwiftUI: UIViewRepresentable {
////    let controller: RController?
//    
////    public init(viewModel: RViewModel, controller: RController? = nil) {
////        self.controller = controller ?? RController(viewModel)
////    }
//    
//    let viewModel: RViewModel
//    
//    public init(viewModel: RViewModel) {
//        self.viewModel = viewModel
//    }
//    
//    /// Constructs the view
//    public func makeUIView(context: Context) -> RView {
//        var view: RView
//        let model = controller!.viewModel.model
//        
//        if let resource = controller?.viewModel.model.assetName {
//            view = try! RView(
//                resource: resource,
//                fit: model.fit,
//                alignment: model.alignment,
//                autoplay: model.autoplay,
//                artboard: model.artboard,
//                animation: model.animation,
//                stateMachine: model.stateMachine
//            )
//        }
//        else if let httpUrl = controller?.viewModel.model.url {
//            view = try! RView(
//                httpUrl: httpUrl,
//                fit: model.fit,
//                alignment: model.alignment,
//                autoplay: model.autoplay,
//                artboard: model.artboard,
//                animation: model.animation,
//                stateMachine: model.stateMachine
//            )
//        }
//        else {
//            view = RView()
//        }
//        
//        controller?.register(view:view)
//        return view
//    }
//    
//    public func updateUIView(_ view: RView, context: UIViewRepresentableContext<RViewSwiftUI>) {
//        let newFit: RiveRuntime.Fit = controller?.viewModel.model.fit ?? .fitContain
//        let newAlignment: RiveRuntime.Alignment = controller?.viewModel.model.alignment ?? .alignmentCenter
//        
//        if (newFit != view.fit) {
//            view.fit = newFit
//        }
//        
//        if (newAlignment != view.alignment) {
//            view.alignment = newAlignment
//        }
//    }
//    
//    public static func dismantleUIView(_ view: RView, coordinator: Self.Coordinator) {
//        view.stop()
//        
//        // TODO: is this neccessary
//        coordinator.controller?.deregisterView()
//    }
//    
//    // Constructs a coordinator for managing updating state
//    public func makeCoordinator() -> Coordinator {
//        return Coordinator(controller: controller)
//    }
//}
//
//// MARK: - Coordinator
//extension RViewSwiftUI {
//    public class Coordinator: NSObject {
//        public var controller: RController?
//        
//        init(controller: RController?) {
//            self.controller = controller
//        }
//    }
//}

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
            touchEvent = RTouchEvent(type: .touchUp, location: CGPoint.zero, index: 0)
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
