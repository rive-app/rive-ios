//
//  MockSemanticsElementDelegate.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 4/23/26.
//  Copyright © 2026 Rive. All rights reserved.
//

@testable import RiveRuntime

#if !os(macOS) || RIVE_MAC_CATALYST

class MockSemanticsElementDelegate: SemanticsElementDelegate {
    var focusedElements: [SemanticsElement] = []
    var lostFocusElements: [SemanticsElement] = []
    var activatedElements: [SemanticsElement] = []
    var activateReturnValue = false
    var incrementedElements: [SemanticsElement] = []
    var decrementedElements: [SemanticsElement] = []

    func elementDidBecomeFocused(_ element: SemanticsElement) {
        focusedElements.append(element)
    }

    func elementDidLoseFocus(_ element: SemanticsElement) {
        lostFocusElements.append(element)
    }

    func elementDidActivate(_ element: SemanticsElement) -> Bool {
        activatedElements.append(element)
        return activateReturnValue
    }

    func elementDidIncrement(_ element: SemanticsElement) {
        incrementedElements.append(element)
    }

    func elementDidDecrement(_ element: SemanticsElement) {
        decrementedElements.append(element)
    }
}

#endif
