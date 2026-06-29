//
//  SemanticsNode.swift
//  RiveRuntime
//
//  Created by David Skuza on 4/22/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import Foundation

// MARK: - SemanticAction

/// Accessibility actions supported by a semantic node, mapped from VoiceOver
/// gestures to the corresponding C++ ``SemanticActionType``.
struct SemanticAction: OptionSet {
    let rawValue: UInt8
    static let tap      = SemanticAction(rawValue: 1 << 0)
    static let increase = SemanticAction(rawValue: 1 << 1)
    static let decrease = SemanticAction(rawValue: 1 << 2)
}

// MARK: - SemanticsNode

/// Internal representation of a semantic node in the accessibility tree.
///
/// Immutable value type. Mirrors the data from ``SemanticsDiffNode`` but uses
/// Swift-native types (e.g., `UInt32?` instead of `-1` for root). When the
/// C++ runtime reports changes, a new ``SemanticsNode`` replaces the old one
/// in the manager's dictionary.
///
/// Stored in the manager's flat `nodes` dictionary for O(1) diff lookups,
/// while ``children`` arrays provide the tree structure for depth-first ordering.
struct SemanticsNode {
    /// Unique identifier assigned by the C++ runtime.
    let nodeID: UInt32
    /// Parent node ID, or `nil` if this is a root node. Translated from C++ `-1`.
    let parentID: UInt32?
    /// The semantic role (text, button, image, etc.). Determines which
    /// accessibility traits are applied and whether an element is created.
    let role: SemanticRole
    /// Primary text announced by VoiceOver. Maps to `accessibilityLabel`.
    let label: String
    /// Current value (e.g., slider percentage). Maps to `accessibilityValue`.
    let value: String
    /// Usage hint (e.g., "double tap to activate"). Maps to `accessibilityHint`.
    let hint: String
    /// Bitmask of current state flags (hidden, disabled, selected, etc.).
    let stateFlags: SemanticState
    /// Bitmask of trait flags declaring which states are applicable to this node.
    let traitFlags: SemanticTrait
    /// Heading level (1–6) for heading semantics. 0 means not a heading.
    let headingLevel: UInt32
    /// Bounding rectangle in pixel space (as reported by the C++ runtime).
    /// Converted to points when assigned to `accessibilityFrame`.
    let bounds: CGRect
    /// Ordered list of child node IDs. Drives the depth-first walk for
    /// building the ordered elements array.
    let children: [UInt32]

    /// Creates a node from a C++ diff node.
    ///
    /// For `added` nodes, children defaults to empty (populated later via
    /// `childrenUpdated`). For `moved` and `updatedSemantic`, pass the
    /// existing node's children to preserve them.
    init(from diffNode: SemanticsDiffNode, children: [UInt32] = []) {
        self.nodeID = diffNode.nodeID
        self.parentID = diffNode.parentNodeID
        self.role = diffNode.role
        self.label = diffNode.label
        self.value = diffNode.value
        self.hint = diffNode.hint
        self.stateFlags = diffNode.stateFlags
        self.traitFlags = diffNode.traitFlags
        self.headingLevel = diffNode.headingLevel
        self.bounds = CGRect(
            x: CGFloat(diffNode.minX),
            y: CGFloat(diffNode.minY),
            width: CGFloat(diffNode.maxX - diffNode.minX),
            height: CGFloat(diffNode.maxY - diffNode.minY)
        )
        self.children = children
    }

    /// Returns a copy with only bounds replaced.
    func withBounds(_ bounds: CGRect) -> SemanticsNode {
        SemanticsNode(
            nodeID: nodeID, parentID: parentID, role: role,
            label: label, value: value, hint: hint,
            stateFlags: stateFlags, traitFlags: traitFlags,
            headingLevel: headingLevel, bounds: bounds,
            children: children
        )
    }

    /// Returns a copy with a new children array.
    func withChildren(_ children: [UInt32]) -> SemanticsNode {
        SemanticsNode(
            nodeID: nodeID, parentID: parentID, role: role,
            label: label, value: value, hint: hint,
            stateFlags: stateFlags, traitFlags: traitFlags,
            headingLevel: headingLevel, bounds: bounds,
            children: children
        )
    }

    /// Whether this node should have a corresponding ``SemanticsElement``.
    /// Nodes that are hidden or have zero-area bounds are filtered out.
    var isAccessibilityVisible: Bool {
        !isHidden && bounds.width > 0 && bounds.height > 0
    }

    /// Whether this node's element should act as an accessibility container.
    /// Container elements hold child accessibility elements that VoiceOver
    /// groups together for navigation.
    var isContainer: Bool {
        switch role {
        // semantics-reference.md § "Container Roles"
        case .tabList, .list, .group, .dialog, .alertDialog, .radioGroup:
            return true
        case .text, .button, .tab, .listItem,
             .none, .link, .checkbox, .switchControl,
             .slider, .textField, .image,
             .radioButton:
            return false
        @unknown default:
            return false
        }
    }

    /// Whether the node is enabled.
    ///
    /// Uses the trait-gated state model: a node without the `.enablable` trait
    /// is not considered disabled — the concept simply doesn't apply to it.
    var isEnabled: Bool {
        !traitFlags.contains(.enablable) || !stateFlags.contains(.disabled)
    }

    /// Whether the node is currently selected.
    ///
    /// Only meaningful when the node has the `.selectable` trait.
    var isSelected: Bool {
        traitFlags.contains(.selectable) && stateFlags.contains(.selected)
    }

    /// Whether the node is currently checked (and not mixed/indeterminate).
    ///
    /// Only meaningful when the node has the `.checkable` trait.
    /// Mixed state is treated as not-checked for `.selected` trait purposes.
    var isChecked: Bool {
        traitFlags.contains(.checkable) && stateFlags.contains(.checked) && !stateFlags.contains(.mixed)
    }

    /// Whether the node is in a mixed/indeterminate state.
    ///
    /// Only meaningful when the node has the `.checkable` trait.
    var isMixed: Bool {
        traitFlags.contains(.checkable) && stateFlags.contains(.mixed)
    }

    /// Whether the node is currently toggled on.
    ///
    /// Only meaningful when the node has the `.toggleable` trait.
    var isToggled: Bool {
        traitFlags.contains(.toggleable) && stateFlags.contains(.toggled)
    }

    /// Whether the expandable trait applies to this node.
    var isExpandable: Bool {
        traitFlags.contains(.expandable)
    }

    /// Whether the node is currently expanded.
    ///
    /// Only meaningful when the node has the `.expandable` trait.
    var isExpanded: Bool {
        traitFlags.contains(.expandable) && stateFlags.contains(.expanded)
    }

    /// Whether the node can receive screen-reader focus.
    var isFocusable: Bool {
        traitFlags.contains(.focusable)
    }

    /// Whether the node is modal.
    ///
    /// semantics-reference.md § "Non-Trait States": Modal tells the platform
    /// to trap focus within this container and prevent interaction with
    /// content behind it.
    var isModal: Bool {
        (role == .dialog || role == .alertDialog) && stateFlags.contains(.modal)
    }

    /// Whether this node is a live region whose changes should be
    /// announced by VoiceOver even when the element doesn't have focus.
    ///
    /// Non-trait-gated — applies unconditionally regardless of traits.
    var isLiveRegion: Bool {
        stateFlags.contains(.liveRegion)
    }

    /// Whether the node is an obscured text field (e.g. a password field).
    ///
    /// Role-gated: only applies to `.textField` nodes. When true, the
    /// accessibility value should be suppressed to prevent VoiceOver from
    /// reading sensitive content aloud.
    var isObscured: Bool {
        role == .textField && stateFlags.contains(.obscured)
    }

    /// Whether the node is hidden from the accessibility tree.
    ///
    /// Non-trait-gated — applies unconditionally regardless of traits.
    var isHidden: Bool {
        stateFlags.contains(.hidden)
    }

    /// The accessibility actions this node supports, derived from its role.
    var availableActions: SemanticAction {
        switch role {
        case .button, .link, .checkbox, .switchControl, .tab, .radioButton:
            return .tap
        case .slider:
            return [.increase, .decrease]
        case .text, .image, .textField, .group, .list, .listItem,
             .tabList, .none, .dialog, .alertDialog, .radioGroup:
            return []
        @unknown default:
            return []
        }
    }

    private init(
        nodeID: UInt32, parentID: UInt32?, role: SemanticRole,
        label: String, value: String, hint: String,
        stateFlags: SemanticState, traitFlags: SemanticTrait,
        headingLevel: UInt32, bounds: CGRect,
        children: [UInt32]
    ) {
        self.nodeID = nodeID
        self.parentID = parentID
        self.role = role
        self.label = label
        self.value = value
        self.hint = hint
        self.stateFlags = stateFlags
        self.traitFlags = traitFlags
        self.headingLevel = headingLevel
        self.bounds = bounds
        self.children = children
    }
}

#endif
