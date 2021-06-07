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
    
    @IBAction func beginnerButtonTriggered(_ sender: UIButton) {
        beginnerButtonAction?()
    }
    @IBAction func intermediateButtonTriggered(_ sender: UIButton) {
        intermediateButtonAction?()
    }
    
    @IBAction func expertButtonTriggered(_ sender: UIButton) {
        expertButtonAction?()
    }
}
class StateMachineViewController: UIViewController {
    let resourceName = "skills"
    
    override public func loadView() {
        super.loadView()
        
        guard let stateMachineView = view as? StateMachineView else {
            fatalError("Could not find StateMachineView")
        }
        
        stateMachineView.riveView.configure(
            getRiveFile(resourceName: resourceName),
            andStateMachine: "Designer's Test"
        )
        stateMachineView.beginnerButtonAction = {
            stateMachineView.riveView.setNumberState(
                "Designer's Test",
                inputName: "Level",
                value: 0.0
            )
        }
        stateMachineView.intermediateButtonAction = {
            stateMachineView.riveView.setNumberState(
                "Designer's Test",
                inputName: "Level",
                value: 1.0
            )
        }
        stateMachineView.expertButtonAction = {
            stateMachineView.riveView.setNumberState(
                "Designer's Test",
                inputName: "Level",
                value: 2.0
            )
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (view as! StateMachineView).beginnerButtonAction = nil
        (view as! StateMachineView).intermediateButtonAction = nil
        (view as! StateMachineView).expertButtonAction = nil
    }
}
