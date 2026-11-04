//
//  MockFocusSystem.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

@testable import RiveRuntime

@MainActor
final class MockFocusSystem: FocusSystem {
    weak var delegate: (any FocusSystemDelegate)?
    var defaultEntryDirection: FocusTraversalDirection?

    var isFocusable = false {
        didSet {
            isFocusableValues.append(isFocusable)
            onIsFocusableChanged?(isFocusable)
        }
    }

    private(set) var isFocusableValues: [Bool] = []
    private(set) var invalidateCallCount = 0

    var onIsFocusableChanged: ((Bool) -> Void)?

    func exit() {
        delegate?.focusSystemDidExit(self)
    }

    func invalidate() {
        invalidateCallCount += 1
    }
}
