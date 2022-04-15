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
    let viewModel = RViewModel(fileName: "blendmodes")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let rview = RView()
        view.addSubview(rview)
        viewModel.setView(rview)
        rview.frame = view.frame
    }
}
