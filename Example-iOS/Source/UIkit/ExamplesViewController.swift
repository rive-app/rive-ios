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

/// Exposes SwiftUI with the ability to dismiss view from SwiftUI side
@available(iOS 15.0, *)
class ExamplesViewController: UIViewController {
//    @IBSegueAction func showRiveExplorer(_ coder: NSCoder) -> UIViewController? {
//        return HostingController<RiveExplorer>(coder: coder)
//    }
    
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
        return HostingController<LoopView>(coder: coder)
    }

    @IBSegueAction func showStateMachine(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftStateMachine>(coder: coder)
    }

    @IBSegueAction func showMeshExample(_ coder: NSCoder) -> UIViewController? {
        return HostingController<SwiftMeshAnimation>(coder: coder)
    }
    
    @IBAction func showSwiftUISlider(_ sender: Any) {
        let controller = UIHostingController(rootView: RiveSlider().view())
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBSegueAction func showUIKitSlider(_ coder: NSCoder) -> SimpleSliderViewController? {
        return SimpleSliderViewController(coder: coder)
    }
    
    @IBSegueAction func showUIKitMultiAnimations(_ coder: NSCoder) -> MultipleAnimationsController? {
        return MultipleAnimationsController(coder: coder)
    }
}

fileprivate class HostingController<Content: DismissableView>: UIHostingController<Content> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: Content())
        rootView.dismiss = {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

public protocol DismissableView: View {
    init()
    var dismiss: () -> Void { get set }
}
