//
//  ExamplesViewController.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/6/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import SwiftUI
import RiveRuntime

/// Simple way to add SwiftUI to a UIKit app; doesn't have a way to handle dismissing view in SwiftUI
//class ExamplesViewController: UIViewController {
//
//    @IBSegueAction func hostingAction(_ coder: NSCoder) -> UIViewController? {
//        return UIHostingController(coder: coder, rootView: RiveSwiftUIView())
//    }
//}

// Exposes SwiftUI with the ability to dismiss view from SwiftUI side
class ExamplesViewController: UIViewController {
    @IBSegueAction func showRiveExplorer(_ coder: NSCoder) -> UIViewController? {
        return HostingController<RiveExplorer>(coder: coder)
    }
    
    @IBSegueAction func showRiveComponents(_ coder: NSCoder) -> UIViewController? {
        return HostingController<RiveComponents>(coder: coder)
    }

    @IBSegueAction func showSimpleAnimation(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftSimpleAnimation>(coder: coder)
    }

    @IBSegueAction func showLayout(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftLayout>(coder: coder)
    }

    @IBSegueAction func showMultipleAnimations(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftMultipleAnimations>(coder: coder)
    }

    @IBSegueAction func showLoopMode(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftLoopMode>(coder: coder)
    }

    @IBSegueAction func showStateMachine(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftStateMachine>(coder: coder)
    }

    @IBSegueAction func showMeshExample(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftMeshAnimation>(coder: coder)
    }
    
    @IBAction func showNewSwiftUIExample(_ sender: Any) {
        let sliderViewModel = RViewModel.riveslider
        presentRiveResource(sliderViewModel.viewSwift)
    }
}

class HostingController<Content: DismissableView>: UIHostingController<Content> {
    override init(rootView: Content) {
        super.init(rootView: rootView)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: Content())
        sharedInit()
    }
    
    private func sharedInit() {
        rootView.dismiss = dismiss
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

public protocol DismissableView: View {
    init()
    var dismiss: () -> Void { get set }
}

func presentRiveResource(_ resource: RViewModel.StandardView, navigationController: UINavigationController? = nil) {
    let controller = UIHostingController(rootView: resource)
    
    if let navController = navigationController {
        navController.pushViewController(controller, animated: true)
    } else {
        topController()?.present(controller, animated: true)
    }
}

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
