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
    
    @IBSegueAction func hostingAction(_ coder: NSCoder) -> UIViewController? {
        return RiveHostingViewController(coder: coder)
    }
}

class RiveHostingViewController: UIHostingController<RiveSwiftUIView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: RiveSwiftUIView())
        rootView.dismiss = dismiss
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
