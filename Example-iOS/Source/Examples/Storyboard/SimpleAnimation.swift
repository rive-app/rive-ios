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
    var riveFile = try! RiveFile(name: "truck")
    var riveModel: NewRiveModel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        riveModel = try! NewRiveModel(riveFile: riveFile, animationIndex: nil)
        
        let rview = NewRiveView(model: riveModel)
        view.addSubview(rview)
        rview.frame = view.frame
    }
}
