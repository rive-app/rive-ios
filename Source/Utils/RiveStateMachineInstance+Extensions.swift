//
//  RiveStateMachineInstance+Extensions.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 5/13/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

 extension RiveStateMachineInstance {
     @available(*, deprecated, message: "The legacy state machine input API is deprecated. Use Data Binding properties instead. See https://rive.app/docs/runtimes/apple/migrating-from-legacy#state-machine-inputs")
     @objc public var inputs: [StateMachineInput] {
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

 /// State machine input types
 @available(*, deprecated, message: "The legacy state machine input API is deprecated. Use Data Binding properties instead. See https://rive.app/docs/runtimes/apple/migrating-from-legacy#state-machine-inputs")
 @objc public enum StateMachineInputType: IntegerLiteralType {
     case trigger, number, boolean
 }
 /// Simple data type for passing state machine input names and their types
 @available(*, deprecated, message: "The legacy state machine input API is deprecated. Use Data Binding properties instead. See https://rive.app/docs/runtimes/apple/migrating-from-legacy#state-machine-inputs")
 @objc public class StateMachineInput: NSObject {
     public let name: String
     public let type: StateMachineInputType

     init(name: String, type: StateMachineInputType) {
         self.name = name
         self.type = type
     }
 }
