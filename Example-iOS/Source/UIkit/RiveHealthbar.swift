//
//  RiveHealthbar.swift
//  RiveExample
//
//  Created by Zachary Duncan on 3/20/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class RiveHealthbarVC: UIViewController, RViewController {
    @IBOutlet weak var riveView: RiveView!
    @IBOutlet weak var slider: UISlider!
    var viewModel: RResourceViewModel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let resource = RResource(resource: "energy_bar_example", fit: .constant(.fitFill), alignment: .constant(.alignmentCenter), stateMachine: "State Machine ")
        viewModel = RResourceViewModel(resource: resource)
        
        self.riveView = viewModel.viewFromFile()
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        try? viewModel.setNumberState(inputName: "Energy", value: slider.value)
    }
}

protocol RViewController: UIViewController {
    var viewModel: RResourceViewModel! { get set }
}

extension RViewController {
    func presentRiveResource(_ resource: RFacade.ViewSwift, navigationController: UINavigationController? = nil) {
        let controller = UIHostingController(rootView: resource)
        
        if let navController = navigationController {
            navController.pushViewController(controller, animated: true)
        } else {
            topController()?.present(controller, animated: true)
            
            // Modal presentation
            // navigationController?.present(controller, animated: true)
            // navigationController?.modalPresentationStyle = .formSheet
        }
    }
    
//    func presentRiveResource(_ resource: String) {
//        presentRiveResource(RiveResource(resource))
//    }
    
    private func topController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topController(controller: navigationController.visibleViewController)
        }
        
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topController(controller: selected)
            }
        }
        
        if let presented = controller?.presentedViewController {
            return topController(controller: presented)
        }
        return controller
    }
}

class RResourceViewModel {
    @ObservedObject var resource: RResource
    
    var riveViewSwift: RiveViewSwift
    var oldController = RiveController()
    var riveView: RiveView?
    
    init(resource: RResource) {
        self.resource = resource
        riveViewSwift = RiveViewSwift(resource: "")
        
        riveViewSwift = RiveViewSwift(
            resource: resource.resourceName,
            fit: $resource.fit,
            alignment: $resource.alignment,
            autoplay: resource.autoplay,
            artboard: resource.artboard,
            animation: resource.animation,
            stateMachine: resource.stateMachine,
            controller: oldController
        )
        
        // TODO: -
        // - Replace references of controller in RiveViewSwift with RResourceViewModel
        // - Make RiveViewSwift be the model
    }
    
    func viewFromFile() -> RiveView {
        let view = RiveView()
        view.fit = resource.fit
        
        guard let riveFile = try? RiveFile(resource: resource.resourceName) else {
            fatalError("Failed to import Rive file.")
        }
        try? view.configure(riveFile)
        
        return view
    }
    
    public func registerView(_ view: RiveView) {
        riveView = view
    }
    
    public func deregisterView() {
        riveView = nil
    }
    
    public func reset() throws {
        try riveView?.reset()
    }
    
    public func play(_ loop: Loop = .loopAuto, _ direction: Direction = .directionAuto) throws {
        try riveView?.play(loop:loop, direction: direction)
    }
    
    public func play(
        animation: String,
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        stateMachine: Bool = false
    ) throws {
        try riveView?.play(
            animationName: animation,
            loop: loop,
            direction: direction,
            isStateMachine: stateMachine
        )
    }
    public func play(
        animations: [String],
        loop: Loop = .loopAuto,
        direction: Direction = .directionAuto,
        stateMachine: Bool = false
    ) throws {
        try riveView?.play(
            animationNames: animations,
            loop: loop,
            direction: direction,
            isStateMachine: stateMachine
        )
    }
    
    public func pause() {
        riveView?.pause()
    }
    
    public func pause(_ animationName: String, _ isStateMachine: Bool = false) {
        riveView?.pause(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func pause(_ animationNames: [String], _ isStateMachine: Bool = false) {
        riveView?.pause(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    public func stop() {
        riveView?.stop()
    }
    
    public func stop(_ animationNames: [String], _ isStateMachine: Bool = false) {
        riveView?.stop(animationNames: animationNames, isStateMachine: isStateMachine)
    }
    
    public func stop(_ animationName: String, _ isStateMachine: Bool = false) {
        riveView?.stop(animationName: animationName, isStateMachine: isStateMachine)
    }
    
    public func fireState(_ stateMachineName: String, inputName: String) throws {
        try riveView?.fireState(stateMachineName, inputName: inputName)
    }
    
    open func setBooleanState(stateMachine: String? = nil, inputName: String, value: Bool) throws {
        try riveView?.setBooleanState(resource.stateMachine ?? "", inputName: inputName, value: value)
    }
    
    open func setNumberState(stateMachine: String? = nil, inputName: String, value: Float) throws {
        try riveView?.setNumberState(resource.stateMachine ?? "", inputName: inputName, value: value)
    }
}


// Potentially can inherit from HostingViewController instead for better SwiftUI interoperability


