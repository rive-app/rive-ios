//
//  ExamplesViewController.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/6/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import SwiftUI

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
        return RiveExplorerHostingController(coder: coder)
    }
    
    @IBSegueAction func showRiveComponents(_ coder: NSCoder) -> UIViewController? {
        return RiveComponentsHostingController(coder: coder)
    }
    
    @IBSegueAction func showSimpleAnimation(_ coder: NSCoder) -> UIViewController? {
        return SimpleAnimationHostingController(coder: coder)
    }
    
    @IBSegueAction func showLayout(_ coder: NSCoder) -> UIViewController? {
        return LayoutHostingController(coder: coder)
    }
    
    @IBSegueAction func showMultipleAnimations(_ coder: NSCoder) -> UIViewController? {
        return MultipleAnimationsHostingController(coder: coder)
    }
    
    @IBSegueAction func showLoopMode(_ coder: NSCoder) -> UIViewController? {
        return LoopModeHostingController(coder: coder)
    }
    
    @IBSegueAction func showStateMachine(_ coder: NSCoder) -> UIViewController? {
        return StateMachineHostingController(coder: coder)
    }
}


class LoopModeHostingController: UIHostingController<SwiftLoopMode> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SwiftLoopMode())
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}


class StateMachineHostingController: UIHostingController<SwiftStateMachine> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SwiftStateMachine())
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

class MultipleAnimationsHostingController: UIHostingController<SwiftMultipleAnimations> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SwiftMultipleAnimations())
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

class SimpleAnimationHostingController: UIHostingController<SwiftSimpleAnimation> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SwiftSimpleAnimation())
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}


class LayoutHostingController: UIHostingController<SwiftLayout> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SwiftLayout())
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

class RiveExplorerHostingController: UIHostingController<RiveExplorer> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: RiveExplorer())
        rootView.dismiss = dismiss
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

class RiveComponentsHostingController: UIHostingController<RiveComponents> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: RiveComponents())
        rootView.dismiss = dismiss
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
