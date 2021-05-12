//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime


class SimpleAnimationViewController: UIViewController {
    let resourceName = "truck_v7"
    
    
    override public func loadView() {
        super.loadView()
        // Wire up an instance of RiveView to the controller
        let view = RiveView()
        self.view = view
        (self.view! as! RiveView).configure(getRiveFile(resourceName: resourceName))
    }
}
