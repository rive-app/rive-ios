//
//  StateMachine.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 08/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class StateMachineView: UIView {
    typealias ButtonAction = ()->Void
    @IBOutlet var riveView: RiveView!
    
    var beginnerButtonAction: ButtonAction?
    var intermediateButtonAction: ButtonAction?
    var expertButtonAction: ButtonAction?
    var resetButtonAction: ButtonAction?
    
    @IBAction func beginnerButtonTriggered(_ sender: UIButton) {
        beginnerButtonAction?()
    }
    @IBAction func intermediateButtonTriggered(_ sender: UIButton) {
        intermediateButtonAction?()
    }
    
    @IBAction func expertButtonTriggered(_ sender: UIButton) {
        expertButtonAction?()
    }
    
    @IBAction func resetButtonTriggered(_ sender: UIButton) {
        resetButtonAction?()
    }
}

class StateMachineViewController: UIViewController {
    // MARK: RiveViewModel
    // This view model specifies the exact StateMachine that it wants from the file
    var viewModel = RiveViewModel(fileName: "skills", stateMachineName: "Designer's Test")
    
    override public func loadView() {
        super.loadView()
        
        guard let stateMachineView = view as? StateMachineView else {
            fatalError("Could not find StateMachineView")
        }
        
        viewModel.setView(stateMachineView.riveView)
        
        stateMachineView.beginnerButtonAction = {
            self.viewModel.setInput("Level", value: 0.0)
        }
        stateMachineView.intermediateButtonAction = {
            self.viewModel.setInput("Level", value: 1.0)
        }
        stateMachineView.expertButtonAction = {
            self.viewModel.setInput("Level", value: 2.0)
        }
        stateMachineView.resetButtonAction = {
            self.viewModel.reset()
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (view as! StateMachineView).beginnerButtonAction = nil
        (view as! StateMachineView).intermediateButtonAction = nil
        (view as! StateMachineView).expertButtonAction = nil
    }
}
