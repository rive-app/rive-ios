//
//  MockRiveViewModelInstanceData.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/25/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

@objc class MockRiveViewModelInstanceData: RiveViewModelInstanceData {
    private let _type: RiveViewModelInstanceDataType
    private let _stringValue: String?
    private let _numberValue: NSNumber?
    private let _boolValue: NSNumber?
    private let _colorValue: NSNumber?

    init(type: RiveViewModelInstanceDataType = .none, stringValue: String? = nil, numberValue: NSNumber? = nil, boolValue: NSNumber? = nil, colorValue: NSNumber? = nil) {
        self._type = type
        self._stringValue = stringValue
        self._numberValue = numberValue
        self._boolValue = boolValue
        self._colorValue = colorValue
        super.init()
    }
    
    override var type: RiveViewModelInstanceDataType {
        return _type
    }
    
    override var stringValue: String? {
        return _stringValue
    }
    
    override var numberValue: NSNumber? {
        return _numberValue
    }

    override var boolValue: NSNumber? {
        return _boolValue
    }
    
    override var colorValue: NSNumber? {
        return _colorValue
    }
}

