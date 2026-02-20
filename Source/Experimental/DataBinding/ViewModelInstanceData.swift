//
//  ViewModelInstanceData.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/11/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

struct ViewModelInstanceData: Sendable {
    enum Kind: Sendable {
        case trigger
        case value(Value)
    }

    enum Value: Sendable {
        case string(String)
        case number(Float)
        case boolean(Bool)
        case color(UInt32)
        case none
    }

    let type: Kind

    init(from data: [String: Any]) {
        let typeValue = (data["type"] as? NSNumber)?.intValue
        let dataType = typeValue.flatMap { RiveViewModelInstanceDataType(rawValue: $0) }

        if dataType == .trigger {
            type = .trigger
            return
        }

        if let stringValue = data["stringValue"] as? String {
            type = .value(.string(stringValue))
        } else if let numberValue = data["numberValue"] as? NSNumber {
            type = .value(.number(numberValue.floatValue))
        } else if let booleanValue = data["booleanValue"] as? NSNumber {
            type = .value(.boolean(booleanValue.boolValue))
        } else if let colorValue = data["colorValue"] as? NSNumber {
            type = .value(.color(colorValue.uint32Value))
        } else {
            type = .value(.none)
        }
    }
}
