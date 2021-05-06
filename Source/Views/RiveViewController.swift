//
//  RiveViewController.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

open class RiveViewController: UIViewController {
    

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startRive()
    }
    
    override public func loadView() {
        // Wire up an instance of RiveView to the controller
        let view = RiveView()
        self.view = view
    }
    
    
    open func setRiveFile() -> RiveFile {
        preconditionFailure("This method must be overridden")
    }
    
    
    func startRive() {
        (self.view! as! RiveView).configure(withRiveFile: setRiveFile())
    }
}
