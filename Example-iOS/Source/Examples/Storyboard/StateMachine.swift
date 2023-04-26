//
//  StateMachine.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 08/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class StateMachineViewController: UIViewController {
    @IBOutlet weak var riveView: RiveView!
    
    // MARK: RiveViewModel
    // This view model specifies the exact StateMachine that it wants from the file
    var viewModel = RiveViewModel(fileName: "skills", stateMachineName: "Designer's Test")
    
    
    @IBAction func beginnerButtonTriggered(_ sender: UIButton) {
        viewModel.setInput("Level", value: 0.0)
    }
    @IBAction func intermediateButtonTriggered(_ sender: UIButton) {
        viewModel.setInput("Level", value: 1.0)
    }

    @IBAction func expertButtonTriggered(_ sender: UIButton) {
        viewModel.setInput("Level", value: 2.0)
    }

    @IBAction func resetButtonTriggered(_ sender: UIButton) {
        viewModel.reset()
    }
    
    override public func viewDidLoad() {
        viewModel.setView(riveView)
        
    }
}
