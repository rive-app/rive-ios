//
//  BlendModes.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 11/06/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class BlendModeViewController: UIViewController {
    let resourceName = "blendmodes"
    
    override public func loadView() {
        super.loadView()
        
        let view = RiveView()
        view.fit = Fit.fitContain
        
        guard let riveFile = try? RiveFile(resource: resourceName) else {
            fatalError("Failed to import Rive file.")
        }
        try? view.configure(riveFile)
        self.view = view
        
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}
