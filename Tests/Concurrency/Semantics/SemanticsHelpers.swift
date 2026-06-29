//
//  SemanticsHelpers.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 4/23/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

#if !os(macOS) || RIVE_MAC_CATALYST

// MARK: - Node Helpers

func makeTextNode(
    nodeID: UInt32,
    label: String = "Label",
    parentID: Int32 = -1
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .text, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: parentID, siblingIndex: 0
    )
}

func makeButtonNode(
    nodeID: UInt32,
    label: String = "Button",
    isExpandable: Bool = false,
    isExpanded: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .button, label: label, value: "", hint: "",
        stateFlags: isExpanded ? [.expanded] : [],
        traitFlags: isExpandable ? [.expandable] : [],
        headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeFocusableButtonNode(
    nodeID: UInt32,
    label: String = "Button"
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .button, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [.focusable],
        headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeSliderNode(
    nodeID: UInt32,
    label: String = "Volume",
    value: String = "50%",
    isDisabled: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .slider, label: label, value: value, hint: "",
        stateFlags: isDisabled ? [.disabled] : [],
        traitFlags: isDisabled ? [.enablable] : [],
        headingLevel: 0,
        minX: 0, minY: 0, maxX: 200, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeDialogNode(
    nodeID: UInt32,
    label: String = "Dialog",
    isModal: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .dialog, label: label, value: "", hint: "",
        stateFlags: isModal ? [.modal] : [],
        traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 300, maxY: 200,
        parentID: -1, siblingIndex: 0
    )
}

func makeAlertDialogNode(
    nodeID: UInt32,
    label: String = "Alert",
    isModal: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .alertDialog, label: label, value: "", hint: "",
        stateFlags: isModal ? [.modal] : [],
        traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 300, maxY: 200,
        parentID: -1, siblingIndex: 0
    )
}

func makeSwitchNode(
    nodeID: UInt32,
    label: String = "Dark Mode",
    value: String = "",
    isToggled: Bool = false,
    isDisabled: Bool = false
) -> SemanticsDiffNode {
    var stateFlags: SemanticState = isToggled ? [.toggled] : []
    var traitFlags: SemanticTrait = [.toggleable]
    if isDisabled {
        stateFlags.insert(.disabled)
        traitFlags.insert(.enablable)
    }
    return SemanticsDiffNode(
        id: nodeID, role: .switchControl, label: label, value: value, hint: "",
        stateFlags: stateFlags, traitFlags: traitFlags, headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeImageNode(
    nodeID: UInt32,
    label: String = "Photo"
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .image, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 100,
        parentID: -1, siblingIndex: 0
    )
}

func makeLinkNode(
    nodeID: UInt32,
    label: String = "Learn more"
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .link, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 30,
        parentID: -1, siblingIndex: 0
    )
}

func makeCheckboxNode(
    nodeID: UInt32,
    label: String = "Accept terms",
    isChecked: Bool = false,
    isMixed: Bool = false
) -> SemanticsDiffNode {
    var states: SemanticState = []
    if isChecked { states.insert(.checked) }
    if isMixed { states.insert(.mixed) }
    return SemanticsDiffNode(
        id: nodeID, role: .checkbox, label: label, value: "", hint: "",
        stateFlags: states, traitFlags: [.checkable], headingLevel: 0,
        minX: 0, minY: 0, maxX: 30, maxY: 30,
        parentID: -1, siblingIndex: 0
    )
}

func makeRadioGroupNode(
    nodeID: UInt32,
    label: String = "Options"
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .radioGroup, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 200, maxY: 100,
        parentID: -1, siblingIndex: 0
    )
}

func makeRadioButtonNode(
    nodeID: UInt32,
    label: String = "Option A",
    isSelected: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .radioButton, label: label, value: "", hint: "",
        stateFlags: isSelected ? [.selected] : [],
        traitFlags: [.selectable],
        headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 30,
        parentID: -1, siblingIndex: 0
    )
}

func makeTextFieldNode(
    nodeID: UInt32,
    label: String = "Username",
    value: String = "",
    isObscured: Bool = false
) -> SemanticsDiffNode {
    var stateFlags: SemanticState = []
    if isObscured { stateFlags.insert(.obscured) }
    return SemanticsDiffNode(
        id: nodeID, role: .textField, label: label, value: value, hint: "",
        stateFlags: stateFlags, traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 200, maxY: 40,
        parentID: -1, siblingIndex: 0
    )
}

func makeStructuralNode(nodeID: UInt32) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .none, label: "", value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 0, maxY: 0,
        parentID: -1, siblingIndex: 0
    )
}

func makeGroupNode(
    nodeID: UInt32,
    label: String = ""
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .group, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 300, maxY: 200,
        parentID: -1, siblingIndex: 0
    )
}

func makeTabListNode(nodeID: UInt32, label: String = "") -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .tabList, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 300, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeTabNode(
    nodeID: UInt32,
    label: String = "Tab",
    isSelected: Bool = false
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .tab, label: label, value: "", hint: "",
        stateFlags: isSelected ? [.selected] : [],
        traitFlags: [.selectable],
        headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

func makeListNode(nodeID: UInt32, label: String = "") -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .list, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 300, maxY: 200,
        parentID: -1, siblingIndex: 0
    )
}

func makeListItemNode(
    nodeID: UInt32,
    label: String = "Item"
) -> SemanticsDiffNode {
    SemanticsDiffNode(
        id: nodeID, role: .listItem, label: label, value: "", hint: "",
        stateFlags: [], traitFlags: [], headingLevel: 0,
        minX: 0, minY: 0, maxX: 100, maxY: 50,
        parentID: -1, siblingIndex: 0
    )
}

// MARK: - Diff Helper

func makeDiff(
    rootID: UInt32,
    removed: [NSNumber] = [],
    added: [SemanticsDiffNode] = [],
    moved: [SemanticsDiffNode] = [],
    childrenUpdated: [SemanticsChildrenUpdate] = [],
    updatedSemantic: [SemanticsDiffNode] = [],
    updatedGeometry: [SemanticsBoundsUpdate] = []
) -> SemanticsDiff {
    SemanticsDiff(
        frameNumber: 1,
        treeVersion: 1,
        rootID: rootID,
        removed: removed,
        added: added,
        moved: moved,
        childrenUpdated: childrenUpdated,
        updatedSemantic: updatedSemantic,
        updatedGeometry: updatedGeometry
    )
}

// MARK: - Manager / Element Helpers

@MainActor
func makeManager(
    delegate: MockSemanticsManagerDelegate? = nil
) -> SemanticsManager {
    SemanticsManager(delegate: delegate ?? MockSemanticsManagerDelegate())
}

@MainActor
func makeElement(
    nodeID: UInt32 = 1,
    delegate: SemanticsElementDelegate? = nil
) -> SemanticsElement {
    SemanticsElement(nodeID: nodeID, accessibilityContainer: NSObject(), delegate: delegate ?? MockSemanticsElementDelegate())
}

// MARK: - SemanticsManager Test Extension

extension SemanticsManager {
    func applyDiff(_ diff: SemanticsDiff) {
        enqueue(diff: diff)
        commitDiffs()
    }
}

#endif
