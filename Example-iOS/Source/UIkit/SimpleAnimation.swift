//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI

class SimpleAnimationViewController: UIViewController {
    var viewModel = RViewModel(fileName: "truck")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let rview = RView()
        view.addSubview(rview)
        viewModel.setView(rview)
        rview.frame = view.frame
    }
}
