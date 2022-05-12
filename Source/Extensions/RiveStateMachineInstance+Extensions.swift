//
//  RiveStateMachineInstance+Extensions.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 5/12/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

extension RiveStateMachineInstance {
    open var inputs: [StateMachineInput] {
        var inputs: [StateMachineInput] = []
        
        for i in 0 ..< inputCount() {
            let input = try! input(from: i)
            var type: StateMachineInputType = .boolean
            
            if input.isTrigger() {
                type = .trigger
            } else if input.isNumber() {
                type = .number
            }
            
            inputs.append(StateMachineInput(name: input.name(), type: type))
        }
        
        return inputs
    }
}
