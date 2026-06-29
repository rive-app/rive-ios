//
//  SemanticsManagerTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 4/21/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
@preconcurrency @testable import RiveRuntime

#if !os(macOS) || RIVE_MAC_CATALYST

// MARK: - SemanticsNode Tests

class SemanticsNodeTests: XCTestCase {

    // MARK: - Init

    @MainActor
    func test_init_mapsAllPropertiesFromDiffNode() {
        let diffNode = SemanticsDiffNode(
            id: 42,
            role: .text,
            label: "Hello",
            value: "World",
            hint: "Greeting",
            stateFlags: [.disabled],
            traitFlags: [.enablable],
            headingLevel: 2,
            minX: 10,
            minY: 20,
            maxX: 110,
            maxY: 70,
            parentID: 5,
            siblingIndex: 0
        )

        let node = SemanticsNode(from: diffNode)

        XCTAssertEqual(node.nodeID, 42)
        XCTAssertEqual(node.role, .text)
        XCTAssertEqual(node.label, "Hello")
        XCTAssertEqual(node.value, "World")
        XCTAssertEqual(node.hint, "Greeting")
        XCTAssertEqual(node.stateFlags, [.disabled])
        XCTAssertEqual(node.traitFlags, [.enablable])
        XCTAssertEqual(node.headingLevel, 2)
        XCTAssertEqual(node.parentID, 5)
        XCTAssertEqual(node.bounds, CGRect(x: 10, y: 20, width: 100, height: 50))
        XCTAssertTrue(node.children.isEmpty)
    }

    @MainActor
    func test_init_convertsNegativeParentIDToNil() {
        let diffNode = makeTextNode(nodeID: 1, parentID: -1)
        let node = SemanticsNode(from: diffNode)
        XCTAssertNil(node.parentID)
    }

    @MainActor
    func test_init_convertsPositiveParentIDToValue() {
        let diffNode = makeTextNode(nodeID: 1, parentID: 5)
        let node = SemanticsNode(from: diffNode)
        XCTAssertEqual(node.parentID, 5)
    }

    @MainActor
    func test_init_preservesExistingChildren() {
        let diffNode = makeTextNode(nodeID: 1)
        let node = SemanticsNode(from: diffNode, children: [10, 20, 30])
        XCTAssertEqual(node.children, [10, 20, 30])
    }

    // MARK: - Copy helpers

    @MainActor
    func test_withBounds_returnsNewNodeWithUpdatedBounds() {
        let diffNode = makeTextNode(nodeID: 1)
        let node = SemanticsNode(from: diffNode, children: [5])
        let updated = node.withBounds(CGRect(x: 50, y: 60, width: 200, height: 300))

        XCTAssertEqual(updated.bounds, CGRect(x: 50, y: 60, width: 200, height: 300))
        XCTAssertEqual(updated.nodeID, 1)
        XCTAssertEqual(updated.children, [5])
    }

    @MainActor
    func test_withChildren_returnsNewNodeWithUpdatedChildren() {
        let diffNode = makeTextNode(nodeID: 1)
        let node = SemanticsNode(from: diffNode)
        let updated = node.withChildren([7, 8, 9])

        XCTAssertEqual(updated.children, [7, 8, 9])
        XCTAssertEqual(updated.nodeID, 1)
    }

    // MARK: - isAccessibilityVisible

    @MainActor
    func test_isAccessibilityVisible_textNotHiddenNonZeroBounds_returnsTrue() {
        let node = SemanticsNode(from: makeTextNode(nodeID: 1))
        XCTAssertTrue(node.isAccessibilityVisible)
    }

    @MainActor
    func test_isAccessibilityVisible_noneRole_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .none, label: "None", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isAccessibilityVisible)
    }

    @MainActor
    func test_isAccessibilityVisible_hiddenState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Hidden", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isAccessibilityVisible)
    }

    @MainActor
    func test_isAccessibilityVisible_zeroBounds_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Zero", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 0, maxY: 0, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isAccessibilityVisible)
    }

    // MARK: - isEnabled

    @MainActor
    func test_isEnabled_withoutEnablableTrait_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [.disabled], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isEnabled)
    }

    @MainActor
    func test_isEnabled_enablableAndNotDisabled_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [.enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isEnabled)
    }

    @MainActor
    func test_isEnabled_enablableAndDisabled_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [.disabled], traitFlags: [.enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isEnabled)
    }

    // MARK: - isSelected

    @MainActor
    func test_isSelected_selectableAndSelected_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [.selected], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isSelected)
    }

    @MainActor
    func test_isSelected_selectableAndNotSelected_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isSelected)
    }

    @MainActor
    func test_isSelected_notSelectable_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [.selected], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isSelected)
    }

    // MARK: - isModal

    @MainActor
    func test_isModal_dialog_withModalState_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .dialog, label: "Alert", value: "", hint: "",
            stateFlags: [.modal], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isModal)
    }

    @MainActor
    func test_isModal_dialog_withoutModalState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .dialog, label: "Alert", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isModal)
    }

    @MainActor
    func test_isModal_alertDialog_withoutModalState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .alertDialog, label: "Alert", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isModal)
    }

    @MainActor
    func test_isModal_alertDialog_withModalState_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .alertDialog, label: "Alert", value: "", hint: "",
            stateFlags: [.modal], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isModal)
    }

    @MainActor
    func test_isModal_otherRole_withoutModalState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "OK", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isModal)
    }

    @MainActor
    func test_isModal_otherRole_withModalState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [.modal], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isModal)
    }

    // MARK: - isLiveRegion

    @MainActor
    func test_isLiveRegion_withLiveRegionState_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Status", value: "", hint: "",
            stateFlags: [.liveRegion], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isLiveRegion)
    }

    @MainActor
    func test_isLiveRegion_withoutLiveRegionState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Status", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isLiveRegion)
    }

    // MARK: - isHidden

    @MainActor
    func test_isHidden_withHiddenState_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isHidden)
    }

    @MainActor
    func test_isHidden_withoutHiddenState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isHidden)
    }

    // MARK: - isContainer

    @MainActor
    func test_isContainer_tabListRole_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isContainer)
    }

    @MainActor
    func test_isContainer_tabRole_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tab, label: "Tab", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_isContainer_textRole_returnsFalse() {
        let node = SemanticsNode(from: makeTextNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    // MARK: - isContainer (list)

    @MainActor
    func test_isContainer_listRole_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .list, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isContainer)
    }

    @MainActor
    func test_isContainer_listItemRole_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .listItem, label: "Item", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isContainer)
    }

    // MARK: - isContainer (group)

    @MainActor
    func test_isContainer_groupRole_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isContainer)
    }

    // MARK: - Slider

    @MainActor
    func test_isContainer_sliderRole_returnsFalse() {
        let node = SemanticsNode(from: makeSliderNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    // MARK: - Switch Control

    @MainActor
    func test_isContainer_switchControlRole_returnsFalse() {
        let node = SemanticsNode(from: makeSwitchNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_availableActions_switchControlRole_containsTap() {
        let node = SemanticsNode(from: makeSwitchNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, .tap)
    }

    @MainActor
    func test_isToggled_toggleableAndToggled_returnsTrue() {
        let node = SemanticsNode(from: makeSwitchNode(nodeID: 1, isToggled: true))
        XCTAssertTrue(node.isToggled)
    }

    @MainActor
    func test_isToggled_toggleableAndNotToggled_returnsFalse() {
        let node = SemanticsNode(from: makeSwitchNode(nodeID: 1, isToggled: false))
        XCTAssertFalse(node.isToggled)
    }

    @MainActor
    func test_isToggled_withoutToggleableTrait_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .switchControl, label: "Test", value: "", hint: "",
            stateFlags: [.toggled], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isToggled)
    }

    // MARK: - Image

    @MainActor
    func test_isContainer_imageRole_returnsFalse() {
        let node = SemanticsNode(from: makeImageNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_availableActions_imageRole_isEmpty() {
        let node = SemanticsNode(from: makeImageNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, [])
    }

    // MARK: - Link

    @MainActor
    func test_isContainer_linkRole_returnsFalse() {
        let node = SemanticsNode(from: makeLinkNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_availableActions_linkRole_containsTap() {
        let node = SemanticsNode(from: makeLinkNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, .tap)
    }

    // MARK: - Checkbox

    @MainActor
    func test_isChecked_checkableAndChecked_returnsTrue() {
        let node = SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: true))
        XCTAssertTrue(node.isChecked)
    }

    @MainActor
    func test_isChecked_checkableAndUnchecked_returnsFalse() {
        let node = SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: false))
        XCTAssertFalse(node.isChecked)
    }

    @MainActor
    func test_isChecked_checkableAndMixed_returnsFalse() {
        let node = SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: true, isMixed: true))
        XCTAssertFalse(node.isChecked)
    }

    @MainActor
    func test_isChecked_withoutCheckableTrait_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .checkbox, label: "Test", value: "", hint: "",
            stateFlags: [.checked], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 30, maxY: 30, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isChecked)
    }

    @MainActor
    func test_isMixed_checkableAndMixed_returnsTrue() {
        let node = SemanticsNode(from: makeCheckboxNode(nodeID: 1, isMixed: true))
        XCTAssertTrue(node.isMixed)
    }

    @MainActor
    func test_isMixed_checkableAndNotMixed_returnsFalse() {
        let node = SemanticsNode(from: makeCheckboxNode(nodeID: 1, isMixed: false))
        XCTAssertFalse(node.isMixed)
    }

    @MainActor
    func test_isMixed_withoutCheckableTrait_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .checkbox, label: "Test", value: "", hint: "",
            stateFlags: [.mixed], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 30, maxY: 30, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isMixed)
    }

    // MARK: - TextField

    @MainActor
    func test_isContainer_textFieldRole_returnsFalse() {
        let node = SemanticsNode(from: makeTextFieldNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_availableActions_textFieldRole_returnsEmpty() {
        let node = SemanticsNode(from: makeTextFieldNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, [])
    }

    @MainActor
    func test_isObscured_textFieldWithObscuredState_returnsTrue() {
        let node = SemanticsNode(from: makeTextFieldNode(nodeID: 1, isObscured: true))
        XCTAssertTrue(node.isObscured)
    }

    @MainActor
    func test_isObscured_textFieldWithoutObscuredState_returnsFalse() {
        let node = SemanticsNode(from: makeTextFieldNode(nodeID: 1, isObscured: false))
        XCTAssertFalse(node.isObscured)
    }

    @MainActor
    func test_isObscured_nonTextFieldWithObscuredState_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "B", value: "", hint: "",
            stateFlags: .obscured, traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isObscured)
    }

    // MARK: - RadioGroup / RadioButton

    @MainActor
    func test_isContainer_radioGroupRole_returnsTrue() {
        let node = SemanticsNode(from: makeRadioGroupNode(nodeID: 1))
        XCTAssertTrue(node.isContainer)
    }

    @MainActor
    func test_isContainer_radioButtonRole_returnsFalse() {
        let node = SemanticsNode(from: makeRadioButtonNode(nodeID: 1))
        XCTAssertFalse(node.isContainer)
    }

    @MainActor
    func test_availableActions_radioButtonRole_returnsTap() {
        let node = SemanticsNode(from: makeRadioButtonNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, .tap)
    }

    @MainActor
    func test_availableActions_radioGroupRole_returnsEmpty() {
        let node = SemanticsNode(from: makeRadioGroupNode(nodeID: 1))
        XCTAssertEqual(node.availableActions, [])
    }

    // MARK: - Dialog / AlertDialog

    @MainActor
    func test_isContainer_dialogRole_returnsTrue() {
        let node = SemanticsNode(from: makeDialogNode(nodeID: 1))
        XCTAssertTrue(node.isContainer)
    }

    @MainActor
    func test_isContainer_alertDialogRole_returnsTrue() {
        let node = SemanticsNode(from: makeAlertDialogNode(nodeID: 1))
        XCTAssertTrue(node.isContainer)
    }

    @MainActor
    func test_availableActions_dialogRole_isEmpty() {
        let node = SemanticsNode(from: makeDialogNode(nodeID: 1))
        XCTAssertTrue(node.availableActions.isEmpty)
    }

    @MainActor
    func test_availableActions_alertDialogRole_isEmpty() {
        let node = SemanticsNode(from: makeAlertDialogNode(nodeID: 1))
        XCTAssertTrue(node.availableActions.isEmpty)
    }

    // MARK: - isExpandable / isExpanded

    @MainActor
    func test_isExpandable_withExpandableTrait_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Menu", value: "", hint: "",
            stateFlags: [], traitFlags: [.expandable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isExpandable)
    }

    @MainActor
    func test_isExpandable_withoutExpandableTrait_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isExpandable)
    }

    @MainActor
    func test_isExpanded_expandableAndExpanded_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Menu", value: "", hint: "",
            stateFlags: [.expanded], traitFlags: [.expandable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isExpanded)
    }

    @MainActor
    func test_isExpanded_expandableAndNotExpanded_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Menu", value: "", hint: "",
            stateFlags: [], traitFlags: [.expandable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isExpanded)
    }

    @MainActor
    func test_isExpanded_notExpandable_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [.expanded], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isExpanded)
    }

    // MARK: - isFocusable

    @MainActor
    func test_isFocusable_withFocusableTrait_returnsTrue() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Input", value: "", hint: "",
            stateFlags: [], traitFlags: [.focusable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.isFocusable)
    }

    @MainActor
    func test_isFocusable_withoutFocusableTrait_returnsFalse() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertFalse(node.isFocusable)
    }

    // MARK: - availableActions

    @MainActor
    func test_availableActions_buttonRole_containsTap() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertEqual(node.availableActions, .tap)
    }

    @MainActor
    func test_availableActions_tabRole_containsTap() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertEqual(node.availableActions, .tap)
    }

    @MainActor
    func test_availableActions_sliderRole_containsIncreaseAndDecrease() {
        let node = SemanticsNode(from: makeSliderNode(nodeID: 1))
        XCTAssertTrue(node.availableActions.contains(.increase))
        XCTAssertTrue(node.availableActions.contains(.decrease))
        XCTAssertFalse(node.availableActions.contains(.tap))
    }

    @MainActor
    func test_availableActions_textRole_isEmpty() {
        let node = SemanticsNode(from: makeTextNode(nodeID: 1))
        XCTAssertTrue(node.availableActions.isEmpty)
    }

    @MainActor
    func test_availableActions_groupRole_isEmpty() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let node = SemanticsNode(from: diffNode)
        XCTAssertTrue(node.availableActions.isEmpty)
    }

}

// MARK: - SemanticsElement Tests

class SemanticsElementTests: XCTestCase {

    @MainActor
    func test_configure_setsLabel() {
        let element = makeElement()
        let node = SemanticsNode(from: makeTextNode(nodeID: 1, label: "Hello"))

        element.configure(from: node)

        XCTAssertEqual(element.accessibilityLabel, "Hello")
    }

    @MainActor
    func test_configure_setsValue_whenNonEmpty() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "L", value: "42%", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityValue, "42%")
    }

    @MainActor
    func test_configure_setsValueNil_whenEmpty() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextNode(nodeID: 1)))

        XCTAssertNil(element.accessibilityValue)
    }

    @MainActor
    func test_configure_setsHint_whenNonEmpty() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "L", value: "", hint: "Double tap",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityHint, "Double tap")
    }

    @MainActor
    func test_configure_setsHintNil_whenEmpty() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextNode(nodeID: 1)))

        XCTAssertNil(element.accessibilityHint)
    }

    @MainActor
    func test_configure_setsStaticTextTrait_forTextRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextNode(nodeID: 1)))

        XCTAssertTrue(element.accessibilityTraits.contains(.staticText))
    }

    @MainActor
    func test_configure_setsImageTrait_forImageRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeImageNode(nodeID: 1)))

        XCTAssertTrue(element.accessibilityTraits.contains(.image))
    }

    @MainActor
    func test_configure_setsLinkTrait_forLinkRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeLinkNode(nodeID: 1)))

        XCTAssertTrue(element.accessibilityTraits.contains(.link))
    }

    @MainActor
    func test_configure_setsToggleButtonTrait_forCheckboxRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeCheckboxNode(nodeID: 1)))

        if #available(iOS 17.0, *) {
            XCTAssertTrue(element.accessibilityTraits.contains(.toggleButton))
            XCTAssertFalse(element.accessibilityTraits.contains(.button))
        } else {
            XCTAssertTrue(element.accessibilityTraits.contains(.button))
        }
    }

    @MainActor
    func test_configure_checkboxChecked_setsSelectedTrait() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: true)))

        XCTAssertTrue(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_checkboxUnchecked_doesNotSetSelectedTrait() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: false)))

        XCTAssertFalse(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_checkboxMixed_doesNotSetSelectedTrait() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeCheckboxNode(nodeID: 1, isChecked: true, isMixed: true)))

        XCTAssertFalse(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_setsButtonTrait_forRadioButtonRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeRadioButtonNode(nodeID: 1)))

        XCTAssertTrue(element.accessibilityTraits.contains(.button))
    }

    @MainActor
    func test_configure_radioButtonSelected_setsSelectedTrait() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeRadioButtonNode(nodeID: 1, isSelected: true)))

        XCTAssertTrue(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_radioButtonUnselected_doesNotSetSelectedTrait() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeRadioButtonNode(nodeID: 1, isSelected: false)))

        XCTAssertFalse(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_radioGroup_setsSemanticGroupContainerType() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeRadioGroupNode(nodeID: 1)))

        XCTAssertEqual(element.accessibilityContainerType, .semanticGroup)
    }

    @MainActor
    func test_configure_radioGroup_isNotAccessibilityElement() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeRadioGroupNode(nodeID: 1)))

        XCTAssertFalse(element.isAccessibilityElement)
    }

    @MainActor
    func test_configure_textFieldRole_setsValueFromNode() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextFieldNode(nodeID: 1, label: "Username", value: "john")))

        XCTAssertEqual(element.accessibilityLabel, "Username")
        XCTAssertEqual(element.accessibilityValue, "john")
    }

    @MainActor
    func test_configure_obscuredTextField_suppressesValue() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextFieldNode(nodeID: 1, value: "s3cret", isObscured: true)))

        XCTAssertNil(element.accessibilityValue)
    }

    @MainActor
    func test_configure_nonObscuredTextField_passesValueThrough() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextFieldNode(nodeID: 1, value: "visible", isObscured: false)))

        XCTAssertEqual(element.accessibilityValue, "visible")
    }

    @MainActor
    func test_configure_setsHeaderTrait_forHeadingLevel() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "H", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 2,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.header))
    }

    @MainActor
    func test_configure_setsNotEnabledTrait_whenDisabled() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "D", value: "", hint: "",
            stateFlags: [.disabled], traitFlags: [.enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
    }

    @MainActor
    func test_configure_setsSelectedTrait_whenSelected() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "S", value: "", hint: "",
            stateFlags: [.selected], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_setsUpdatesFrequentlyTrait_forLiveRegion() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Status", value: "", hint: "",
            stateFlags: [.liveRegion], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.updatesFrequently))
    }

    @MainActor
    func test_configure_doesNotSetUpdatesFrequentlyTrait_withoutLiveRegion() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTextNode(nodeID: 1)))

        XCTAssertFalse(element.accessibilityTraits.contains(.updatesFrequently))
    }

    @MainActor
    func test_configure_setsTabBarTrait_forTabListRole() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tabList, label: "Nav", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.tabBar))
    }

    @MainActor
    func test_configure_setsSemanticGroupContainerType_forTabListRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeTabListNode(nodeID: 1)))

        XCTAssertEqual(element.accessibilityContainerType, .semanticGroup)
    }

    @MainActor
    func test_configure_resetsContainerType_whenRoleChangesToNonContainer() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeListNode(nodeID: 1)))
        XCTAssertEqual(element.accessibilityContainerType, .list)

        element.configure(from: SemanticsNode(from: makeTextNode(nodeID: 1)))
        XCTAssertEqual(element.accessibilityContainerType, .none)
    }

    @MainActor
    func test_configure_setsSelectedTrait_forSelectedTab() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [.selected], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_doesNotSetSelectedTrait_forUnselectedTab() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tab, label: "Settings", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertFalse(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_setsButtonTrait_forTabRole() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .tab, label: "Tab", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.button))
        XCTAssertFalse(element.accessibilityTraits.contains(.staticText))
    }

    // MARK: - Button

    @MainActor
    func test_configure_setsButtonTrait_forButtonRole() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.button))
    }

    // MARK: - Slider

    @MainActor
    func test_configure_setsAdjustableTrait_forSliderRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeSliderNode(nodeID: 1)))

        XCTAssertTrue(element.accessibilityTraits.contains(.adjustable))
    }

    @MainActor
    func test_configure_setsValue_forSliderRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeSliderNode(nodeID: 1, value: "75%")))

        XCTAssertEqual(element.accessibilityValue, "75%")
    }

    @MainActor
    func test_configure_setsNotEnabledAndAdjustableTraits_forDisabledSlider() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .slider, label: "Volume", value: "50%", hint: "",
            stateFlags: [.disabled], traitFlags: [.enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 200, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.adjustable))
        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
    }

    @MainActor
    func test_accessibilityIncrement_callsDelegate() {
        let delegate = MockSemanticsElementDelegate()
        let element = makeElement(delegate: delegate)

        element.accessibilityIncrement()

        XCTAssertEqual(delegate.incrementedElements.count, 1)
        XCTAssertTrue(delegate.incrementedElements.first === element)
    }

    @MainActor
    func test_accessibilityDecrement_callsDelegate() {
        let delegate = MockSemanticsElementDelegate()
        let element = makeElement(delegate: delegate)

        element.accessibilityDecrement()

        XCTAssertEqual(delegate.decrementedElements.count, 1)
        XCTAssertTrue(delegate.decrementedElements.first === element)
    }

    // MARK: - Value Pass-Through

    @MainActor
    func test_configure_passesValueThrough_forExpandableNode() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Menu", value: "3 items", hint: "",
            stateFlags: [.expanded], traitFlags: [.expandable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityValue, "3 items")
    }

    @MainActor
    func test_configure_setsNilValue_whenValueIsEmpty() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .button, label: "Menu", value: "", hint: "",
            stateFlags: [.expanded], traitFlags: [.expandable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertNil(element.accessibilityValue)
    }

    // MARK: - Dialog / AlertDialog

    @MainActor
    func test_configure_setsSemanticGroupContainerType_forDialogRole() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .dialog, label: "Dialog", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityContainerType, .semanticGroup)
    }

    @MainActor
    func test_configure_setsSemanticGroupContainerType_forAlertDialogRole() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .alertDialog, label: "Warning", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityContainerType, .semanticGroup)
    }

    // MARK: - Switch Control

    @MainActor
    func test_configure_setsToggleButtonAndButtonTraits_forSwitchControlRole() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeSwitchNode(nodeID: 1)))

        if #available(iOS 17.0, *) {
            XCTAssertTrue(element.accessibilityTraits.contains(.toggleButton))
            XCTAssertTrue(element.accessibilityTraits.contains(.button))
        } else {
            XCTAssertTrue(element.accessibilityTraits.contains(.button))
        }
    }

    @MainActor
    func test_configure_setsSelectedTrait_forToggledSwitchControl() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeSwitchNode(nodeID: 1, isToggled: true)))

        XCTAssertTrue(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_doesNotSetSelectedTrait_forUntoggledSwitchControl() {
        let element = makeElement()
        element.configure(from: SemanticsNode(from: makeSwitchNode(nodeID: 1, isToggled: false)))

        XCTAssertFalse(element.accessibilityTraits.contains(.selected))
    }

    @MainActor
    func test_configure_setsValue_forSwitchControl() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .switchControl, label: "Dark Mode", value: "On", hint: "",
            stateFlags: [.toggled], traitFlags: [.toggleable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertEqual(element.accessibilityValue, "On")
    }

    @MainActor
    func test_configure_setsNotEnabledTrait_forDisabledSwitchControl() {
        let diffNode = SemanticsDiffNode(
            id: 1, role: .switchControl, label: "Dark Mode", value: "", hint: "",
            stateFlags: [.disabled], traitFlags: [.toggleable, .enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let element = makeElement()
        element.configure(from: SemanticsNode(from: diffNode))

        XCTAssertTrue(element.accessibilityTraits.contains(.button))
        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
    }

    // MARK: - accessibilityActivate

    @MainActor
    func test_accessibilityActivate_callsDelegate() {
        let delegate = MockSemanticsElementDelegate()
        delegate.activateReturnValue = true
        let element = makeElement(delegate: delegate)

        let result = element.accessibilityActivate()

        XCTAssertEqual(delegate.activatedElements.count, 1)
        XCTAssertTrue(result)
    }

    @MainActor
    func test_accessibilityActivate_returnsFalse_whenNoDelegate() {
        let element = SemanticsElement(nodeID: 1, accessibilityContainer: NSObject(), delegate: MockSemanticsElementDelegate())

        let result = element.accessibilityActivate()

        XCTAssertFalse(result)
    }

    // MARK: - Focus Delegate

    @MainActor
    func test_accessibilityElementDidBecomeFocused_callsDelegate() {
        let delegate = MockSemanticsElementDelegate()
        let element = makeElement(delegate: delegate)

        element.accessibilityElementDidBecomeFocused()

        XCTAssertEqual(delegate.focusedElements.count, 1)
        XCTAssertTrue(delegate.focusedElements.first === element)
    }

    @MainActor
    func test_accessibilityElementDidBecomeFocused_noDelegate_doesNotCrash() {
        let element = makeElement()
        element.accessibilityElementDidBecomeFocused()
    }

    @MainActor
    func test_accessibilityElementDidLoseFocus_callsDelegate() {
        let delegate = MockSemanticsElementDelegate()
        let element = makeElement(delegate: delegate)

        element.accessibilityElementDidLoseFocus()

        XCTAssertEqual(delegate.lostFocusElements.count, 1)
        XCTAssertTrue(delegate.lostFocusElements.first === element)
    }

    @MainActor
    func test_accessibilityElementDidLoseFocus_noDelegate_doesNotCrash() {
        let element = makeElement()
        element.accessibilityElementDidLoseFocus()
    }

}

// MARK: - SemanticsManager Tests

class SemanticsManagerTests: XCTestCase {

    // MARK: - Added

    @MainActor
    func test_applyDiff_added_createsElementForVisibleTextNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.nodeID, 1)
    }

    @MainActor
    func test_applyDiff_added_createsElementForImageNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeImageNode(nodeID: 1, label: "Photo")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Photo")
        XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.image) ?? false)
    }

    @MainActor
    func test_applyDiff_added_createsElementForLinkNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeLinkNode(nodeID: 1, label: "Learn more")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Learn more")
        XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.link) ?? false)
    }

    @MainActor
    func test_applyDiff_added_createsElementForCheckboxNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeCheckboxNode(nodeID: 1, label: "Accept terms", isChecked: true)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Accept terms")
        if #available(iOS 17.0, *) {
            XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.toggleButton) ?? false)
        } else {
            XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.button) ?? false)
        }
        XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.selected) ?? false)
    }

    @MainActor
    func test_applyDiff_added_createsElementForRadioButtonNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeRadioButtonNode(nodeID: 1, label: "Option A", isSelected: true)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Option A")
        XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.button) ?? false)
        XCTAssertTrue(manager.accessibilityElements.first?.accessibilityTraits.contains(.selected) ?? false)
    }

    @MainActor
    func test_applyDiff_added_radioGroupContainsRadioButtons() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeRadioGroupNode(nodeID: 1),
                makeRadioButtonNode(nodeID: 2, label: "A"),
                makeRadioButtonNode(nodeID: 3, label: "B"),
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)]),
            ]
        )
        manager.applyDiff(diff)

        let topElements = manager.accessibilityElements
        XCTAssertEqual(topElements.count, 1)
        let radioGroup = topElements.first
        XCTAssertFalse(radioGroup?.isAccessibilityElement ?? true)
        XCTAssertEqual(radioGroup?.childElements?.count, 2)
        XCTAssertEqual(radioGroup?.childElements?[0].accessibilityLabel, "A")
        XCTAssertEqual(radioGroup?.childElements?[1].accessibilityLabel, "B")
    }

    @MainActor
    func test_applyDiff_added_createsElementForTextFieldNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextFieldNode(nodeID: 1, label: "Username", value: "john")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Username")
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityValue, "john")
    }

    @MainActor
    func test_applyDiff_added_doesNotCreateElementForNonTextNode() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0)]
        )

        manager.applyDiff(diff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    @MainActor
    func test_applyDiff_added_doesNotCreateElementForHiddenTextNode() {
        let manager = makeManager()
        let node = SemanticsDiffNode(
            id: 1, role: .text, label: "Hidden", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let diff = makeDiff(rootID: 1, added: [node])

        manager.applyDiff(diff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    // MARK: - Removed

    @MainActor
    func test_applyDiff_removed_removesNodeAndElement() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.count, 1)

        let removeDiff = makeDiff(rootID: 0, removed: [NSNumber(value: 1)])
        manager.applyDiff(removeDiff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    // MARK: - Moved

    @MainActor
    func test_applyDiff_moved_updatesNodeAndReconfiguresElement() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1, label: "Before")])
        manager.applyDiff(addDiff)

        let movedNode = SemanticsDiffNode(
            id: 1, role: .text, label: "After", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 50, minY: 60, maxX: 150, maxY: 110,
            parentID: -1, siblingIndex: 0
        )
        let moveDiff = makeDiff(rootID: 1, moved: [movedNode])
        manager.applyDiff(moveDiff)

        let element = manager.accessibilityElements.first
        XCTAssertEqual(element?.accessibilityLabel, "After")
        XCTAssertEqual(element?.accessibilityFrameInContainerSpace, CGRect(x: 50, y: 60, width: 100, height: 50))
    }

    @MainActor
    func test_applyDiff_moved_preservesExistingChildren() {
        let manager = makeManager()
        let root = makeStructuralNode(nodeID: 0)
        let parent = makeStructuralNode(nodeID: 1)
        let child = makeTextNode(nodeID: 2, label: "Child")

        let addDiff = makeDiff(
            rootID: 0,
            added: [root, parent, child],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.map(\.accessibilityLabel), ["Child"])

        let movedParent = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 10, minY: 10, maxX: 110, maxY: 60,
            parentID: -1, siblingIndex: 0
        )
        let moveDiff = makeDiff(rootID: 0, moved: [movedParent])
        manager.applyDiff(moveDiff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.childElements?.map(\.accessibilityLabel), ["Child"])
    }

    @MainActor
    func test_applyDiff_moved_removesElement_whenBecomesHidden() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1, label: "Visible")])
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.count, 1)

        let hiddenNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Visible", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 50, minY: 60, maxX: 150, maxY: 110,
            parentID: -1, siblingIndex: 0
        )
        let moveDiff = makeDiff(rootID: 1, moved: [hiddenNode])
        manager.applyDiff(moveDiff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    @MainActor
    func test_applyDiff_moved_createsElement_whenBecomesVisible() {
        let manager = makeManager()
        let hiddenNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Hidden", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50,
            parentID: -1, siblingIndex: 0
        )
        let addDiff = makeDiff(rootID: 1, added: [hiddenNode])
        manager.applyDiff(addDiff)
        XCTAssertTrue(manager.accessibilityElements.isEmpty)

        let visibleNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Now Visible", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 50, minY: 60, maxX: 150, maxY: 110,
            parentID: -1, siblingIndex: 0
        )
        let moveDiff = makeDiff(rootID: 1, moved: [visibleNode])
        manager.applyDiff(moveDiff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Now Visible")
    }

    // MARK: - Children Updated

    @MainActor
    func test_applyDiff_childrenUpdated_reordersElements() {
        let manager = makeManager()
        let root = makeStructuralNode(nodeID: 0)
        let childA = makeTextNode(nodeID: 1, label: "A")
        let childB = makeTextNode(nodeID: 2, label: "B")

        let addDiff = makeDiff(
            rootID: 0,
            added: [root, childA, childB],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])]
        )
        manager.applyDiff(addDiff)

        XCTAssertEqual(manager.accessibilityElements.map(\.accessibilityLabel), ["A", "B"])

        let reorderDiff = makeDiff(
            rootID: 0,
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 2), NSNumber(value: 1)])]
        )
        manager.applyDiff(reorderDiff)

        XCTAssertEqual(manager.accessibilityElements.map(\.accessibilityLabel), ["B", "A"])
    }

    @MainActor
    func test_applyDiff_childrenUpdated_rootLevelParentID_doesNotCreateCycle() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 1,
            added: [makeTextNode(nodeID: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: -1, childIDs: [NSNumber(value: 1)])]
        )
        manager.applyDiff(diff)

        let elements = manager.accessibilityElements
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements.first?.accessibilityLabel, "Label")
    }

    @MainActor
    func test_applyDiff_childrenUpdated_implicitRoot_walksRootChildren() {
        let manager = makeManager()
        // rootID=0 but node 0 is never added — the root is implicit.
        // The parentID: -1 childrenUpdated declares the top-level ordering.
        let diff = makeDiff(
            rootID: 0,
            added: [makeTextNode(nodeID: 1, label: "A"), makeTextNode(nodeID: 2, label: "B")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: -1, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])]
        )
        manager.applyDiff(diff)

        let elements = manager.accessibilityElements
        XCTAssertEqual(elements.map(\.accessibilityLabel), ["A", "B"])
    }

    // MARK: - Updated Semantic

    @MainActor
    func test_applyDiff_updatedSemantic_reconfiguresElement() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1, label: "Old")])
        manager.applyDiff(addDiff)

        let updatedNode = SemanticsDiffNode(
            id: 1, role: .text, label: "New", value: "val", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 1, updatedSemantic: [updatedNode])
        manager.applyDiff(updateDiff)

        let element = manager.accessibilityElements.first
        XCTAssertEqual(element?.accessibilityLabel, "New")
        XCTAssertEqual(element?.accessibilityValue, "val")
    }

    @MainActor
    func test_applyDiff_updatedSemantic_visibleToVisible_preservesElementIdentity() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1, label: "Before")])
        manager.applyDiff(addDiff)

        let elementBefore = manager.accessibilityElements.first

        let updatedNode = SemanticsDiffNode(
            id: 1, role: .text, label: "After", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 1, updatedSemantic: [updatedNode])
        manager.applyDiff(updateDiff)

        let elementAfter = manager.accessibilityElements.first
        XCTAssertTrue(elementBefore === elementAfter)
        XCTAssertEqual(elementAfter?.accessibilityLabel, "After")
    }

    @MainActor
    func test_applyDiff_updatedSemantic_removesElement_whenBecomesHidden() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.count, 1)

        let hiddenNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Label", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 1, updatedSemantic: [hiddenNode])
        manager.applyDiff(updateDiff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_createsElement_whenBecomesVisible() {
        let manager = makeManager()
        let hiddenNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Label", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let addDiff = makeDiff(rootID: 1, added: [hiddenNode])
        manager.applyDiff(addDiff)
        XCTAssertTrue(manager.accessibilityElements.isEmpty)

        let visibleNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Label", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 1, updatedSemantic: [visibleNode])
        manager.applyDiff(updateDiff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_roleChangeToContainer_rebuildsOrdering() {
        let manager = makeManager()
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTextNode(nodeID: 1, label: "Child"),
                makeTextNode(nodeID: 2, label: "Nested")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.map(\.accessibilityLabel), ["Child"])

        let groupNode = SemanticsDiffNode(
            id: 1, role: .group, label: "Child", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 0, updatedSemantic: [groupNode])
        manager.applyDiff(updateDiff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.childElements?.map(\.accessibilityLabel), ["Nested"])
    }

    @MainActor
    func test_applyDiff_updatedSemantic_roleChangeFromContainer_rebuildsOrdering() {
        let manager = makeManager()
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeTextNode(nodeID: 2, label: "Nested")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.first?.childElements?.count, 1)

        let textNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Flat", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 300, maxY: 200, parentID: -1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 0, updatedSemantic: [textNode])
        manager.applyDiff(updateDiff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.accessibilityLabel, "Flat")
        XCTAssertNil(topLevel.first?.childElements)
    }

    // MARK: - Updated Geometry

    @MainActor
    func test_applyDiff_updatedGeometry_updatesElementFrame() {
        let delegate = MockSemanticsManagerDelegate()
        delegate.displayScale = 2.0
        let manager = makeManager(delegate: delegate)
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 20, minY: 40, maxX: 120, maxY: 140)
        let geoDiff = makeDiff(rootID: 1, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        let element = manager.accessibilityElements.first
        XCTAssertEqual(element?.accessibilityFrameInContainerSpace, CGRect(x: 10, y: 20, width: 50, height: 50))
    }

    @MainActor
    func test_applyDiff_updatedGeometry_ignoredForHiddenNode() {
        let manager = makeManager()
        let hiddenNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Hidden", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 0, maxY: 0,
            parentID: -1, siblingIndex: 0
        )
        let addDiff = makeDiff(rootID: 1, added: [hiddenNode])
        manager.applyDiff(addDiff)

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 10, minY: 20, maxX: 110, maxY: 120)
        let geoDiff = makeDiff(rootID: 1, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedGeometry_removesElement_whenBoundsShrinkToZero() {
        let manager = makeManager()
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)
        XCTAssertEqual(manager.accessibilityElements.count, 1)

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 0, minY: 0, maxX: 0, maxY: 0)
        let geoDiff = makeDiff(rootID: 1, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        XCTAssertTrue(manager.accessibilityElements.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedGeometry_createsElement_whenBoundsGrowFromZero() {
        let manager = makeManager()
        let zeroNode = SemanticsDiffNode(
            id: 1, role: .text, label: "Label", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 0, maxY: 0,
            parentID: -1, siblingIndex: 0
        )
        let addDiff = makeDiff(rootID: 1, added: [zeroNode])
        manager.applyDiff(addDiff)
        XCTAssertTrue(manager.accessibilityElements.isEmpty)

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 0, minY: 0, maxX: 100, maxY: 50)
        let geoDiff = makeDiff(rootID: 1, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Label")
    }

    @MainActor
    func test_applyDiff_updatedGeometry_visibilityTransition_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)
        delegate.commitDiffsCount = 0

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 0, minY: 0, maxX: 0, maxY: 0)
        manager.applyDiff(makeDiff(rootID: 1, updatedGeometry: [boundsUpdate]))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_applyDiff_updatedGeometry_nonContainerVisibleNode_updatesFrameIncrementally() {
        let delegate = MockSemanticsManagerDelegate()
        delegate.displayScale = 2.0
        let manager = makeManager(delegate: delegate)

        let tabList = SemanticsDiffNode(
            id: 1, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 250,
            parentID: -1, siblingIndex: 0
        )
        let tab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 120, minY: 210, maxX: 220, maxY: 240,
            parentID: 1, siblingIndex: 0
        )
        let addDiff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), tabList, tab],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)

        _ = manager.accessibilityElements

        let boundsUpdate = SemanticsBoundsUpdate(id: 2, minX: 140, minY: 210, maxX: 240, maxY: 240)
        let geoDiff = makeDiff(rootID: 0, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        let tabElement = manager.accessibilityElements.first?.childElements?.first
        // Tab at (140, 210) inside tabList at (100, 200) → relative frame (20, 5) at scale 2.0
        XCTAssertEqual(tabElement?.accessibilityFrameInContainerSpace, CGRect(x: 20, y: 5, width: 50, height: 15))
    }

    @MainActor
    func test_applyDiff_updatedGeometry_containerNode_updatesChildRelativeFrames() {
        let manager = makeManager()

        let tabList = SemanticsDiffNode(
            id: 1, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 250,
            parentID: -1, siblingIndex: 0
        )
        let tab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 120, minY: 210, maxX: 220, maxY: 240,
            parentID: 1, siblingIndex: 0
        )
        let addDiff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), tabList, tab],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)

        _ = manager.accessibilityElements

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 50, minY: 100, maxX: 350, maxY: 150)
        let geoDiff = makeDiff(rootID: 0, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        let tabElement = manager.accessibilityElements.first?.childElements?.first
        // Tab still at (120, 210) but tabList moved to (50, 100) → relative frame (70, 110)
        XCTAssertEqual(tabElement?.accessibilityFrameInContainerSpace, CGRect(x: 70, y: 110, width: 100, height: 30))
    }

    @MainActor
    func test_applyDiff_updatedGeometry_topLevelNonContainerNode_usesAbsoluteFrame() {
        let delegate = MockSemanticsManagerDelegate()
        delegate.displayScale = 1.0
        let manager = makeManager(delegate: delegate)
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)

        _ = manager.accessibilityElements

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 50, minY: 60, maxX: 200, maxY: 110)
        let geoDiff = makeDiff(rootID: 1, updatedGeometry: [boundsUpdate])
        manager.applyDiff(geoDiff)

        let element = manager.accessibilityElements.first
        XCTAssertEqual(element?.accessibilityFrameInContainerSpace, CGRect(x: 50, y: 60, width: 150, height: 50))
    }

    @MainActor
    func test_applyDiff_updatedGeometry_containerNode_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)
        delegate.commitDiffsCount = 0

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 50, minY: 100, maxX: 350, maxY: 150)
        manager.applyDiff(makeDiff(rootID: 0, updatedGeometry: [boundsUpdate]))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_applyDiff_updatedGeometry_nonContainerNode_doesNotNotifyDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let addDiff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(addDiff)
        delegate.commitDiffsCount = 0

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 10, minY: 20, maxX: 110, maxY: 70)
        manager.applyDiff(makeDiff(rootID: 1, updatedGeometry: [boundsUpdate]))

        XCTAssertEqual(delegate.commitDiffsCount, 0)
    }

    // MARK: - Depth-First Ordering

    @MainActor
    func test_accessibilityElements_returnsDepthFirstOrder() {
        let manager = makeManager()

        // Tree:
        //   root(0)
        //     group(1)
        //       text(3) "C"
        //     text(2) "B"
        //     text(4) "A"
        let root = makeStructuralNode(nodeID: 0)
        let group = makeStructuralNode(nodeID: 1)
        let textA = makeTextNode(nodeID: 4, label: "A")
        let textB = makeTextNode(nodeID: 2, label: "B")
        let textC = makeTextNode(nodeID: 3, label: "C")

        let diff = makeDiff(
            rootID: 0,
            added: [root, group, textA, textB, textC],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 4)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let labels = manager.accessibilityElements.map(\.accessibilityLabel)
        XCTAssertEqual(labels, ["C", "B", "A"])
    }

    @MainActor
    func test_accessibilityElements_excludesNonVisibleNodesFromOrdering() {
        let manager = makeManager()

        let root = makeStructuralNode(nodeID: 0)
        let text = makeTextNode(nodeID: 1, label: "Visible")
        let group = makeStructuralNode(nodeID: 2)

        let diff = makeDiff(
            rootID: 0,
            added: [root, text, group],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        XCTAssertEqual(manager.accessibilityElements.count, 1)
        XCTAssertEqual(manager.accessibilityElements.first?.accessibilityLabel, "Visible")
    }

    // MARK: - parentNodeID Extensions

    @MainActor
    func test_diffNode_parentNodeID_negativeToNil() {
        let node = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: -1, siblingIndex: 0
        )
        XCTAssertNil(node.parentNodeID)
    }

    @MainActor
    func test_diffNode_parentNodeID_positiveToValue() {
        let node = SemanticsDiffNode(
            id: 1, role: .text, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 0, minY: 0, maxX: 10, maxY: 10, parentID: 5, siblingIndex: 0
        )
        XCTAssertEqual(node.parentNodeID, 5)
    }

    @MainActor
    func test_childrenUpdate_parentNodeID_negativeToNil() {
        let update = SemanticsChildrenUpdate(parentID: -1, childIDs: [])
        XCTAssertNil(update.parentNodeID)
    }

    @MainActor
    func test_childrenUpdate_parentNodeID_positiveToValue() {
        let update = SemanticsChildrenUpdate(parentID: 3, childIDs: [])
        XCTAssertEqual(update.parentNodeID, 3)
    }

    // MARK: - Container Hierarchy

    @MainActor
    func test_applyDiff_tabListWithTabs_topLevelOnlyContainsTabList() {
        let manager = makeManager()
        // Tree: root(group) → tabList → [tab("Home"), tab("Settings")]
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTabNode(nodeID: 3, label: "Settings")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 1)
    }

    @MainActor
    func test_applyDiff_tabListWithTabs_tabListContainsTabChildren() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTabNode(nodeID: 3, label: "Settings")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let tabList = manager.accessibilityElements.first
        let children = tabList?.childElements
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Home", "Settings"])
    }

    @MainActor
    func test_applyDiff_tabList_tabAccessibilityContainerPointsToTabList() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let tabList = manager.accessibilityElements.first
        let tab = tabList?.childElements?.first
        XCTAssertTrue(tab?.accessibilityContainer === tabList)
    }

    @MainActor
    func test_applyDiff_tabList_tabListContainerPointsToView() {
        let container = NSObject()
        let delegate = MockSemanticsManagerDelegate()
        delegate.container = container
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1)
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let tabList = manager.accessibilityElements.first
        XCTAssertTrue(tabList?.accessibilityContainer === container)
    }

    @MainActor
    func test_applyDiff_tabListWithTabs_childFramesAreRelativeToContainer() {
        let manager = makeManager()
        let tabList = SemanticsDiffNode(
            id: 1, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 250,
            parentID: -1, siblingIndex: 0
        )
        let tab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 120, minY: 210, maxX: 220, maxY: 240,
            parentID: 1, siblingIndex: 0
        )
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), tabList, tab],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let tabElement = manager.accessibilityElements.first?.childElements?.first
        // Tab at (120, 210) inside tabList at (100, 200) → relative frame (20, 10)
        XCTAssertEqual(tabElement?.accessibilityFrameInContainerSpace, CGRect(x: 20, y: 10, width: 100, height: 30))
    }

    @MainActor
    func test_applyDiff_tabListWithTabs_childFramesStableAcrossRebuilds() {
        let manager = makeManager()
        let tabList = SemanticsDiffNode(
            id: 1, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 250,
            parentID: -1, siblingIndex: 0
        )
        let tab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 120, minY: 210, maxX: 220, maxY: 240,
            parentID: 1, siblingIndex: 0
        )
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), tabList, tab],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let expectedFrame = CGRect(x: 20, y: 10, width: 100, height: 30)
        XCTAssertEqual(manager.accessibilityElements.first?.childElements?.first?.accessibilityFrameInContainerSpace, expectedFrame)

        // Trigger a second rebuild via a no-op children update.
        let rebuildDiff = makeDiff(
            rootID: 0,
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(rebuildDiff)

        XCTAssertEqual(manager.accessibilityElements.first?.childElements?.first?.accessibilityFrameInContainerSpace, expectedFrame)
    }

    @MainActor
    func test_applyDiff_nestedContainers_innerContainerFrameIsRelativeToOuter() {
        let manager = makeManager()
        let group = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 400,
            parentID: -1, siblingIndex: 0
        )
        let tabList = SemanticsDiffNode(
            id: 2, role: .tabList, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 120, minY: 220, maxX: 380, maxY: 260,
            parentID: 1, siblingIndex: 0
        )
        let tab = SemanticsDiffNode(
            id: 3, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 130, minY: 225, maxX: 230, maxY: 255,
            parentID: 2, siblingIndex: 0
        )
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), group, tabList, tab],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let groupElement = manager.accessibilityElements.first
        let tabListElement = groupElement?.childElements?.first
        let tabElement = tabListElement?.childElements?.first

        // tabList at (120, 220) inside group at (100, 200) → relative (20, 20)
        XCTAssertEqual(tabListElement?.accessibilityFrameInContainerSpace, CGRect(x: 20, y: 20, width: 260, height: 40))
        // tab at (130, 225) inside tabList at (120, 220) → relative (10, 5)
        XCTAssertEqual(tabElement?.accessibilityFrameInContainerSpace, CGRect(x: 10, y: 5, width: 100, height: 30))
    }

    @MainActor
    func test_applyDiff_tabWithTextChildren_doesNotCreateTextElements() {
        let manager = makeManager()
        // Tab absorbs its text children — the C++ runtime flattens
        // child labels into the tab's own label.
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTextNode(nodeID: 3, label: "Home Label")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let tabList = manager.accessibilityElements.first
        let tabs = tabList?.childElements
        XCTAssertEqual(tabs?.count, 1)
        XCTAssertEqual(tabs?.first?.accessibilityLabel, "Home")
        XCTAssertNil(tabs?.first?.childElements)
    }

    @MainActor
    func test_applyDiff_tabListChildrenReorder_updatesTabOrder() {
        let manager = makeManager()
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTabNode(nodeID: 3, label: "Settings")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(addDiff)

        let reorderDiff = makeDiff(
            rootID: 0,
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 3), NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(reorderDiff)

        let children = manager.accessibilityElements.first?.childElements
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Settings", "Home"])
    }

    @MainActor
    func test_applyDiff_removedTab_disappearsFromTabListChildren() {
        let manager = makeManager()
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTabNode(nodeID: 3, label: "Settings")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(addDiff)

        let removeDiff = makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 3)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(removeDiff)

        let children = manager.accessibilityElements.first?.childElements
        XCTAssertEqual(children?.count, 1)
        XCTAssertEqual(children?.first?.accessibilityLabel, "Home")
    }

    @MainActor
    func test_applyDiff_mixedTopLevel_textAndTabList_correctOrdering() {
        let manager = makeManager()
        // Tree: root(group) → [tabList, text("Content")]
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home"),
                makeTextNode(nodeID: 3, label: "Content")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 3)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 2)
        XCTAssertEqual(topLevel[0].nodeID, 1)
        XCTAssertTrue(topLevel[0].accessibilityTraits.contains(.tabBar))
        XCTAssertEqual(topLevel[1].accessibilityLabel, "Content")
    }

    // MARK: - Action Handlers

    @MainActor
    func test_applyDiff_added_tabElement_activateReturnsTrue() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let tab = manager.accessibilityElements.first?.childElements?.first
        XCTAssertTrue(tab?.accessibilityActivate() == true)
    }

    @MainActor
    func test_applyDiff_added_textElement_activateReturnsFalse() {
        let manager = makeManager()
        let diff = makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)])
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first
        XCTAssertFalse(element?.accessibilityActivate() == true)
    }

    @MainActor
    func test_applyDiff_added_tabElement_activateFiresAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                makeTabNode(nodeID: 2, label: "Home")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let tab = manager.accessibilityElements.first?.childElements?.first
        let result = tab?.accessibilityActivate()

        XCTAssertTrue(result == true)
        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 2)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .tap)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_newElement_activateFiresAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        // Add a hidden tab — no element created.
        let hiddenTab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [.hidden], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: 1, siblingIndex: 0
        )
        let addDiff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeTabListNode(nodeID: 1),
                hiddenTab
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(addDiff)
        XCTAssertNil(manager.accessibilityElements.first?.childElements)

        // Make it visible via updatedSemantic — element should be created and actionable.
        let visibleTab = SemanticsDiffNode(
            id: 2, role: .tab, label: "Home", value: "", hint: "",
            stateFlags: [], traitFlags: [.selectable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: 1, siblingIndex: 0
        )
        let updateDiff = makeDiff(rootID: 0, updatedSemantic: [visibleTab])
        manager.applyDiff(updateDiff)

        let tab = manager.accessibilityElements.first?.childElements?.first
        let result = tab?.accessibilityActivate()
        XCTAssertTrue(result == true)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .tap)
    }

    // MARK: - List/ListItem Hierarchy

    @MainActor
    func test_applyDiff_listWithItems_topLevelOnlyContainsList() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeListNode(nodeID: 1),
                makeListItemNode(nodeID: 2, label: "Item A"),
                makeListItemNode(nodeID: 3, label: "Item B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 1)
    }

    @MainActor
    func test_applyDiff_listWithItems_listContainsItemChildren() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeListNode(nodeID: 1),
                makeListItemNode(nodeID: 2, label: "Item A"),
                makeListItemNode(nodeID: 3, label: "Item B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let list = manager.accessibilityElements.first
        let children = list?.childElements
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Item A", "Item B"])
    }

    @MainActor
    func test_applyDiff_listElement_hasListContainerType() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeListNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let list = manager.accessibilityElements.first
        XCTAssertEqual(list?.accessibilityContainerType, .list)
    }

    @MainActor
    func test_applyDiff_added_listItemElement_activateReturnsFalse() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeListNode(nodeID: 1),
                makeListItemNode(nodeID: 2, label: "Item")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let item = manager.accessibilityElements.first?.childElements?.first
        XCTAssertFalse(item?.accessibilityActivate() == true)
    }

    // MARK: - Group Container

    @MainActor
    func test_applyDiff_groupWithChildren_topLevelOnlyContainsGroup() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeTextNode(nodeID: 2, label: "Child A"),
                makeTextNode(nodeID: 3, label: "Child B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 1)
    }

    @MainActor
    func test_applyDiff_groupWithChildren_groupContainsChildElements() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeTextNode(nodeID: 2, label: "Child A"),
                makeTextNode(nodeID: 3, label: "Child B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let group = manager.accessibilityElements.first
        let children = group?.childElements
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Child A", "Child B"])
    }

    @MainActor
    func test_applyDiff_groupElement_hasSemanticGroupContainerType() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeGroupNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let group = manager.accessibilityElements.first
        XCTAssertEqual(group?.accessibilityContainerType, .semanticGroup)
    }

    @MainActor
    func test_applyDiff_groupWithChildren_childFramesAreRelativeToContainer() {
        let manager = makeManager()
        let group = SemanticsDiffNode(
            id: 1, role: .group, label: "", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 100, minY: 200, maxX: 400, maxY: 400,
            parentID: -1, siblingIndex: 0
        )
        let child = SemanticsDiffNode(
            id: 2, role: .text, label: "Child", value: "", hint: "",
            stateFlags: [], traitFlags: [], headingLevel: 0,
            minX: 120, minY: 210, maxX: 220, maxY: 260,
            parentID: 1, siblingIndex: 0
        )
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), group, child],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let childElement = manager.accessibilityElements.first?.childElements?.first
        XCTAssertEqual(childElement?.accessibilityFrameInContainerSpace, CGRect(x: 20, y: 10, width: 100, height: 50))
    }

    // MARK: - Dialog / AlertDialog

    @MainActor
    func test_applyDiff_added_dialogElement_isContainer() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeDialogNode(nodeID: 1),
                makeTextNode(nodeID: 2, label: "Message")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 1)
    }

    @MainActor
    func test_applyDiff_added_dialogElement_childrenAreNested() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeDialogNode(nodeID: 1),
                makeTextNode(nodeID: 2, label: "Title"),
                makeButtonNode(nodeID: 3, label: "OK")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let dialog = manager.accessibilityElements.first
        let children = dialog?.childElements
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Title", "OK"])
    }

    @MainActor
    func test_applyDiff_added_modalDialog_notifiesDelegateIsModal() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeDialogNode(nodeID: 1, isModal: true)
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        XCTAssertTrue(delegate.lastCommitIsModal)
    }

    @MainActor
    func test_applyDiff_added_dialog_withoutModalState_isNotModal() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeDialogNode(nodeID: 1)
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        XCTAssertFalse(delegate.lastCommitIsModal)
    }

    @MainActor
    func test_applyDiff_added_alertDialogElement_isContainer() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeAlertDialogNode(nodeID: 1, isModal: true),
                makeTextNode(nodeID: 2, label: "Warning"),
                makeButtonNode(nodeID: 3, label: "Dismiss")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2), NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 1)
        XCTAssertTrue(delegate.lastCommitIsModal)

        let children = topLevel.first?.childElements
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.map(\.accessibilityLabel), ["Warning", "Dismiss"])
    }

    @MainActor
    func test_applyDiff_added_alertDialog_withoutModalState_isNotModal() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeButtonNode(nodeID: 1, label: "Background"),
                makeAlertDialogNode(nodeID: 2),
                makeTextNode(nodeID: 3, label: "Alert message"),
                makeButtonNode(nodeID: 4, label: "OK")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3), NSNumber(value: 4)])
            ]
        )
        manager.applyDiff(diff)

        XCTAssertFalse(delegate.lastCommitIsModal)
        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 2)
        XCTAssertEqual(topLevel[0].nodeID, 1)
        XCTAssertEqual(topLevel[1].nodeID, 2)
        XCTAssertEqual(topLevel[1].childElements?.map(\.accessibilityLabel), ["Alert message", "OK"])
    }

    @MainActor
    func test_accessibilityElements_modalDialog_filtersToOnlyModalElement() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeButtonNode(nodeID: 1, label: "Background button"),
                makeDialogNode(nodeID: 2, isModal: true),
                makeTextNode(nodeID: 3, label: "Alert message"),
                makeButtonNode(nodeID: 4, label: "OK")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3), NSNumber(value: 4)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.nodeID, 2)
        XCTAssertEqual(topLevel.first?.childElements?.map(\.accessibilityLabel), ["Alert message", "OK"])
    }

    @MainActor
    func test_accessibilityElements_nonModalContainer_returnsAllElements() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeButtonNode(nodeID: 1, label: "Background button"),
                makeGroupNode(nodeID: 2),
                makeTextNode(nodeID: 3, label: "Info message")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        )
        manager.applyDiff(diff)

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 2)
        XCTAssertEqual(topLevel.map(\.nodeID), [1, 2])
    }

    @MainActor
    func test_accessibilityElements_modalDismissed_restoresAllElements() {
        let manager = makeManager()
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeButtonNode(nodeID: 1, label: "Background"),
                makeDialogNode(nodeID: 2, isModal: true),
                makeTextNode(nodeID: 3, label: "Alert")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))
        XCTAssertEqual(manager.accessibilityElements.count, 1)

        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 2), NSNumber(value: 3)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.accessibilityLabel, "Background")
    }

    @MainActor
    func test_accessibilityElements_nestedModalDialog_trapsToModalElement() {
        let manager = makeManager()
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeDialogNode(nodeID: 2, isModal: true),
                makeTextNode(nodeID: 3, label: "Dialog content"),
                makeButtonNode(nodeID: 4, label: "Background")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 4)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        let topLevel = manager.accessibilityElements
        XCTAssertEqual(topLevel.count, 1)
        XCTAssertEqual(topLevel.first?.accessibilityLabel, "Dialog")
    }

    @MainActor
    func test_commitDiffs_nestedModalDialog_notifiesDelegateIsModal() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeDialogNode(nodeID: 2, isModal: true),
                makeTextNode(nodeID: 3, label: "Dialog content"),
                makeButtonNode(nodeID: 4, label: "Background")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 4)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        XCTAssertTrue(delegate.lastCommitIsModal)
    }

    @MainActor
    func test_applyDiff_dialogElement_hasSemanticGroupContainerType() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeDialogNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let dialog = manager.accessibilityElements.first
        XCTAssertEqual(dialog?.accessibilityContainerType, .semanticGroup)
    }

    // MARK: - Button

    @MainActor
    func test_applyDiff_added_buttonElement_activateReturnsTrue() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Submit")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let button = manager.accessibilityElements.first
        XCTAssertTrue(button?.accessibilityActivate() == true)
    }

    @MainActor
    func test_applyDiff_added_buttonElement_activateFiresAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Submit")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let button = manager.accessibilityElements.first
        let result = button?.accessibilityActivate()

        XCTAssertTrue(result == true)
        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 1)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .tap)
    }

    // MARK: - Slider

    @MainActor
    func test_applyDiff_added_sliderElement_hasAdjustableTrait() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        XCTAssertTrue(slider?.accessibilityTraits.contains(.adjustable) == true)
    }

    @MainActor
    func test_applyDiff_added_sliderElement_setsAccessibilityValue() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, value: "75%")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        XCTAssertEqual(slider?.accessibilityValue, "75%")
    }

    @MainActor
    func test_applyDiff_added_sliderElement_incrementFiresIncreaseAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityIncrement()

        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 1)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .increase)
    }

    @MainActor
    func test_applyDiff_added_sliderElement_decrementFiresDecreaseAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityDecrement()

        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 1)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .decrease)
    }

    @MainActor
    func test_applyDiff_added_sliderElement_activateReturnsFalse() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        XCTAssertFalse(slider?.accessibilityActivate() == true)
    }

    @MainActor
    func test_applyDiff_added_sliderElement_incrementOnNonSlider_doesNotFireAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let text = manager.accessibilityElements.first
        text?.accessibilityIncrement()

        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_sliderValueChange_updatesAccessibilityValue() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, value: "50%")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let updateDiff = makeDiff(
            rootID: 0,
            updatedSemantic: [makeSliderNode(nodeID: 1, value: "75%")]
        )
        manager.applyDiff(updateDiff)

        let slider = manager.accessibilityElements.first
        XCTAssertEqual(slider?.accessibilityValue, "75%")
    }

    // MARK: - Disabled Actions

    @MainActor
    func test_applyDiff_added_disabledSlider_incrementDoesNotFireAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, isDisabled: true)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityIncrement()

        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    @MainActor
    func test_applyDiff_added_disabledSlider_decrementDoesNotFireAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, isDisabled: true)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityDecrement()

        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_sliderBecomesDisabled_incrementDoesNotFireAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let updateDiff = makeDiff(
            rootID: 0,
            updatedSemantic: [makeSliderNode(nodeID: 1, isDisabled: true)]
        )
        manager.applyDiff(updateDiff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityIncrement()

        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    @MainActor
    func test_applyDiff_updatedSemantic_sliderBecomesEnabled_incrementFiresAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, isDisabled: true)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let updateDiff = makeDiff(
            rootID: 0,
            updatedSemantic: [makeSliderNode(nodeID: 1)]
        )
        manager.applyDiff(updateDiff)

        let slider = manager.accessibilityElements.first
        slider?.accessibilityIncrement()

        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .increase)
    }

    @MainActor
    func test_applyDiff_added_disabledButton_activateReturnsFalse() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let disabledButton = SemanticsDiffNode(
            id: 1, role: .button, label: "Submit", value: "", hint: "",
            stateFlags: [.disabled], traitFlags: [.enablable], headingLevel: 0,
            minX: 0, minY: 0, maxX: 100, maxY: 50, parentID: -1, siblingIndex: 0
        )
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), disabledButton],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let button = manager.accessibilityElements.first
        XCTAssertFalse(button?.accessibilityActivate() == true)
        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    // MARK: - Switch Control

    @MainActor
    func test_applyDiff_added_switchControl_createsElement() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSwitchNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let elements = manager.accessibilityElements
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements.first?.accessibilityLabel, "Dark Mode")
        XCTAssertTrue(elements.first?.accessibilityTraits.contains(.button) == true)
    }

    @MainActor
    func test_applyDiff_added_switchControl_activateFiresTap() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSwitchNode(nodeID: 1)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first
        let result = element?.accessibilityActivate()

        XCTAssertTrue(result == true)
        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 1)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .tap)
    }

    @MainActor
    func test_applyDiff_added_disabledSwitchControl_activateReturnsFalse() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSwitchNode(nodeID: 1, isDisabled: true)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first
        XCTAssertFalse(element?.accessibilityActivate() == true)
        XCTAssertTrue(delegate.firedActions.isEmpty)
    }

    @MainActor
    func test_applyDiff_sliderInsideGroup_incrementFiresAction() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeGroupNode(nodeID: 1),
                makeSliderNode(nodeID: 2)
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)]),
                SemanticsChildrenUpdate(parentID: 1, childIDs: [NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first?.childElements?.first
        slider?.accessibilityIncrement()

        XCTAssertEqual(delegate.firedActions.count, 1)
        XCTAssertEqual(delegate.firedActions.first?.nodeID, 2)
        XCTAssertEqual(delegate.firedActions.first?.actionType, .increase)
    }

    @MainActor
    func test_applyDiff_added_sliderElement_emptyValue_setsNilAccessibilityValue() {
        let manager = makeManager()
        let diff = makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeSliderNode(nodeID: 1, value: "")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let slider = manager.accessibilityElements.first
        XCTAssertNil(slider?.accessibilityValue)
    }

    // MARK: - Focus Delegate

    @MainActor
    func test_applyDiff_focusableElement_focusFiresDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeFocusableButtonNode(nodeID: 1, label: "Input")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first
        element?.accessibilityElementDidBecomeFocused()

        XCTAssertEqual(delegate.focusedNodeIDs, [1])
    }

    @MainActor
    func test_applyDiff_nonFocusableElement_focusDoesNotFireDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeButtonNode(nodeID: 1, label: "Submit")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first
        element?.accessibilityElementDidBecomeFocused()

        XCTAssertTrue(delegate.focusedNodeIDs.isEmpty)
    }

    @MainActor
    func test_elementDidLoseFocus_forNonFocusedElement_isNoOp() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeFocusableButtonNode(nodeID: 1, label: "A"),
                makeFocusableButtonNode(nodeID: 2, label: "B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let elementA = manager.accessibilityElements[0]
        let elementB = manager.accessibilityElements[1]
        elementA.accessibilityElementDidBecomeFocused()

        elementB.accessibilityElementDidLoseFocus()

        let expectation = XCTestExpectation(description: "Async check completes")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(delegate.clearFocusCount, 0)
    }

    @MainActor
    func test_elementDidLoseFocus_withNoNewFocus_firesClearFocus() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeFocusableButtonNode(nodeID: 1, label: "A")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])
            ]
        )
        manager.applyDiff(diff)

        let element = manager.accessibilityElements.first!
        element.accessibilityElementDidBecomeFocused()
        element.accessibilityElementDidLoseFocus()

        let expectation = XCTestExpectation(description: "Deferred clear fires")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(delegate.clearFocusCount, 1)
    }

    @MainActor
    func test_elementDidLoseFocus_followedByNewFocus_doesNotFireClearFocus() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        let diff = makeDiff(
            rootID: 0,
            added: [
                makeStructuralNode(nodeID: 0),
                makeFocusableButtonNode(nodeID: 1, label: "A"),
                makeFocusableButtonNode(nodeID: 2, label: "B")
            ],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])
            ]
        )
        manager.applyDiff(diff)

        let elementA = manager.accessibilityElements[0]
        let elementB = manager.accessibilityElements[1]
        elementA.accessibilityElementDidBecomeFocused()
        elementA.accessibilityElementDidLoseFocus()
        elementB.accessibilityElementDidBecomeFocused()

        let expectation = XCTestExpectation(description: "Async check completes")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(delegate.clearFocusCount, 0)
    }

    // MARK: - Layout Update Delegate

    @MainActor
    func test_commitDiffs_withPendingDiffs_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        manager.enqueue(diff: makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)]))

        XCTAssertEqual(delegate.commitDiffsCount, 0)
        manager.commitDiffs()
        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_commitDiffs_withNoPendingDiffs_doesNotNotifyDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)
        manager.enqueue(diff: makeDiff(rootID: 1, added: [makeTextNode(nodeID: 1)]))
        manager.commitDiffs()
        let initial = delegate.commitDiffsCount

        manager.commitDiffs()

        XCTAssertEqual(delegate.commitDiffsCount, initial)
    }

    // MARK: - Modal Focus Transitions

    @MainActor
    func test_commitDiffs_enteringModal_focusesFirstModalChild() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        // Set up a button and focus it.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Trigger")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        manager.accessibilityElements.first?.accessibilityElementDidBecomeFocused()

        // Add a modal dialog — entering modal should focus the first child
        // element inside the dialog so VoiceOver reads the alert content.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeDialogNode(nodeID: 2, isModal: true), makeTextNode(nodeID: 3, label: "Alert message")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        XCTAssertTrue(delegate.lastCommitIsModal)
        XCTAssertEqual(delegate.lastCommitFocusedElement?.accessibilityLabel, "Alert message")
    }

    @MainActor
    func test_commitDiffs_enteringModal_withNoChildren_focusesModalContainer() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Trigger")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        manager.accessibilityElements.first?.accessibilityElementDidBecomeFocused()

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeDialogNode(nodeID: 2, isModal: true)],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])
            ]
        ))

        XCTAssertTrue(delegate.lastCommitIsModal)
        XCTAssertEqual(delegate.lastCommitFocusedElement?.nodeID, 2)
    }

    @MainActor
    func test_commitDiffs_leavingModal_restoresPreModalFocus() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        // Set up a button and focus it.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Trigger")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        let button = manager.accessibilityElements.first!
        button.accessibilityElementDidBecomeFocused()

        // Enter modal.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeDialogNode(nodeID: 2, isModal: true), makeTextNode(nodeID: 3, label: "Alert")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        // Leave modal by removing the dialog.
        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 2), NSNumber(value: 3)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))

        XCTAssertFalse(delegate.lastCommitIsModal)
        XCTAssertTrue(delegate.lastCommitFocusedElement === button)
    }

    @MainActor
    func test_commitDiffs_leavingModal_preModalElementRemoved_passesNil() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        // Set up a button and focus it.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Trigger")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        manager.accessibilityElements.first?.accessibilityElementDidBecomeFocused()

        // Enter modal.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeDialogNode(nodeID: 2, isModal: true), makeTextNode(nodeID: 3, label: "Alert")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        // Leave modal AND remove the original button in the same diff.
        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [])]
        ))

        XCTAssertFalse(delegate.lastCommitIsModal)
        XCTAssertNil(delegate.lastCommitFocusedElement)
    }

    @MainActor
    func test_commitDiffs_modalReplacedByNewModal_preservesPreModalFocus() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        // Set up a button and focus it.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeButtonNode(nodeID: 1, label: "Trigger")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        let button = manager.accessibilityElements.first!
        button.accessibilityElementDidBecomeFocused()

        // Enter modal.
        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeDialogNode(nodeID: 2, isModal: true), makeTextNode(nodeID: 3, label: "First alert")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)]),
                SemanticsChildrenUpdate(parentID: 2, childIDs: [NSNumber(value: 3)])
            ]
        ))

        // Remove old modal and add new modal in one diff.
        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 2), NSNumber(value: 3)],
            added: [makeAlertDialogNode(nodeID: 4, isModal: true), makeTextNode(nodeID: 5, label: "Second alert")],
            childrenUpdated: [
                SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 4)]),
                SemanticsChildrenUpdate(parentID: 4, childIDs: [NSNumber(value: 5)])
            ]
        ))

        // Still modal — preModalFocusedElement should be preserved.
        XCTAssertTrue(delegate.lastCommitIsModal)

        // Now dismiss the second modal.
        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 4), NSNumber(value: 5)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))

        // Should restore focus to the original button.
        XCTAssertFalse(delegate.lastCommitIsModal)
        XCTAssertTrue(delegate.lastCommitFocusedElement === button)
    }

    @MainActor
    func test_commitDiffs_stayingNonModal_passesLastFocusedElement() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1, label: "A"), makeTextNode(nodeID: 2, label: "B")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1), NSNumber(value: 2)])]
        ))
        let elementA = manager.accessibilityElements.first!
        elementA.accessibilityElementDidBecomeFocused()

        manager.applyDiff(makeDiff(
            rootID: 0,
            updatedSemantic: [makeTextNode(nodeID: 2, label: "B updated")]
        ))

        XCTAssertFalse(delegate.lastCommitIsModal)
        XCTAssertTrue(delegate.lastCommitFocusedElement === elementA)
    }

    // MARK: - Notification Suppression

    @MainActor
    func test_commitDiffs_geometryOnly_doesNotNotifyDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        delegate.commitDiffsCount = 0

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 10, minY: 20, maxX: 110, maxY: 70)
        manager.applyDiff(makeDiff(rootID: 0, updatedGeometry: [boundsUpdate]))

        XCTAssertEqual(delegate.commitDiffsCount, 0)
    }

    @MainActor
    func test_commitDiffs_addedNodes_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1, label: "Hello")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_commitDiffs_removedNodes_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        delegate.commitDiffsCount = 0

        manager.applyDiff(makeDiff(
            rootID: 0,
            removed: [NSNumber(value: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [])]
        ))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_commitDiffs_semanticUpdate_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1, label: "Before")],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        delegate.commitDiffsCount = 0

        manager.applyDiff(makeDiff(
            rootID: 0,
            updatedSemantic: [makeTextNode(nodeID: 1, label: "After")]
        ))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_commitDiffs_mixedGeometryAndStructural_notifiesDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.applyDiff(makeDiff(
            rootID: 0,
            added: [makeStructuralNode(nodeID: 0), makeTextNode(nodeID: 1)],
            childrenUpdated: [SemanticsChildrenUpdate(parentID: 0, childIDs: [NSNumber(value: 1)])]
        ))
        delegate.commitDiffsCount = 0

        let boundsUpdate = SemanticsBoundsUpdate(id: 1, minX: 5, minY: 5, maxX: 105, maxY: 55)
        manager.applyDiff(makeDiff(
            rootID: 0,
            updatedSemantic: [makeTextNode(nodeID: 1, label: "Updated")],
            updatedGeometry: [boundsUpdate]
        ))

        XCTAssertEqual(delegate.commitDiffsCount, 1)
    }

    @MainActor
    func test_commitDiffs_emptyDiffs_doesNotNotifyDelegate() {
        let delegate = MockSemanticsManagerDelegate()
        let manager = makeManager(delegate: delegate)

        manager.commitDiffs()

        XCTAssertEqual(delegate.commitDiffsCount, 0)
    }

}

#endif
