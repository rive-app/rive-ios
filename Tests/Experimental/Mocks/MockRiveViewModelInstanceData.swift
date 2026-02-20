//
//  MockRiveViewModelInstanceData.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/25/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

class MockRiveViewModelInstanceData {
    private let type: RiveViewModelInstanceDataType
    private let stringValue: String?
    private let numberValue: NSNumber?
    private let boolValue: NSNumber?
    private let colorValue: NSNumber?

    init(type: RiveViewModelInstanceDataType = .none, stringValue: String? = nil, numberValue: NSNumber? = nil, boolValue: NSNumber? = nil, colorValue: NSNumber? = nil) {
        self.type = type
        self.stringValue = stringValue
        self.numberValue = numberValue
        self.boolValue = boolValue
        self.colorValue = colorValue
    }

    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "type": NSNumber(value: type.rawValue),
            "name": ""
        ]
        if let stringValue {
            result["stringValue"] = stringValue
        }
        if let numberValue {
            result["numberValue"] = numberValue
        }
        if let boolValue {
            result["booleanValue"] = boolValue
        }
        if let colorValue {
            result["colorValue"] = colorValue
        }
        return result
    }
}

extension ViewModelInstanceListener {
    func onViewModelDataReceived(
        _ viewModelInstanceHandle: UInt64,
        requestID: UInt64,
        data: MockRiveViewModelInstanceData
    ) {
        onViewModelDataReceived(
            viewModelInstanceHandle,
            requestID: requestID,
            data: data.dictionary
        )
    }
}

