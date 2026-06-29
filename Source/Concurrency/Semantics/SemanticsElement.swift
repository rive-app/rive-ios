//
//  SemanticsElement.swift
//  RiveRuntime
//
//  Created by David Skuza on 4/22/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

// MARK: - SemanticsElementDelegate

/// Delegate for accessibility events originating from a ``SemanticsElement``.
@MainActor
protocol SemanticsElementDelegate: AnyObject {
    /// Called when VoiceOver moves focus to this element.
    func elementDidBecomeFocused(_ element: SemanticsElement)
    /// Called when VoiceOver moves focus away from this element.
    func elementDidLoseFocus(_ element: SemanticsElement)
    /// Called when the user double-taps to activate. Returns whether the action was handled.
    func elementDidActivate(_ element: SemanticsElement) -> Bool
    /// Called when the user swipes up to increment (e.g. slider).
    func elementDidIncrement(_ element: SemanticsElement)
    /// Called when the user swipes down to decrement (e.g. slider).
    func elementDidDecrement(_ element: SemanticsElement)
}

// MARK: - SemanticsElement

/// An accessibility element backed by a Rive semantic node.
///
/// Created and managed by ``SemanticsManager``. Configures its own
/// accessibility properties (label, value, hint, traits) from
/// a ``SemanticsNode`` via ``configure(from:)``.
class SemanticsElement: UIAccessibilityElement {
    /// The semantic node ID from the C++ runtime. Used for O(1) lookups
    /// when patching elements from incremental diffs.
    let nodeID: UInt32

    /// Ordered child elements for container roles (tabList, etc.).
    /// Exposed to VoiceOver via the `accessibilityElements` override.
    var childElements: [SemanticsElement]?

    /// Delegate notified when VoiceOver focuses or activates this element.
    weak private(set) var delegate: SemanticsElementDelegate?

    override var accessibilityElements: [Any]? {
        get { childElements }
        set { }
    }

    override func accessibilityActivate() -> Bool {
        delegate?.elementDidActivate(self) ?? false
    }

    override func accessibilityElementDidBecomeFocused() {
        delegate?.elementDidBecomeFocused(self)
    }

    override func accessibilityElementDidLoseFocus() {
        delegate?.elementDidLoseFocus(self)
    }

    override func accessibilityIncrement() {
        delegate?.elementDidIncrement(self)
    }

    override func accessibilityDecrement() {
        delegate?.elementDidDecrement(self)
    }

    init(nodeID: UInt32, accessibilityContainer: Any, delegate: SemanticsElementDelegate) {
        self.nodeID = nodeID
        self.delegate = delegate
        super.init(accessibilityContainer: accessibilityContainer)
    }

    /// Configures this element's non-frame accessibility properties from a
    /// semantic node. Frames are set exclusively during the rebuild pass in
    /// ``SemanticsManager/depthFirstCollect`` to avoid transient absolute
    /// frames that VoiceOver could read between rebuilds.
    func configure(from node: SemanticsNode) {
        accessibilityLabel = node.label
        accessibilityHint = node.hint.isEmpty ? nil : node.hint

        if node.isObscured {
            accessibilityValue = nil
        } else {
            accessibilityValue = node.value.isEmpty ? nil : node.value
        }

        isAccessibilityElement = !node.isContainer

        var traits: UIAccessibilityTraits = .none
        switch node.role {
        case .text:
            traits.insert(.staticText)
        case .tabList:
            traits.insert(.tabBar)
        case .button, .radioButton:
            traits.insert(.button)
        case .checkbox:
            if #available(iOS 17.0, tvOS 17.0, macCatalyst 17.0, visionOS 1.0, *) {
                traits.insert(.toggleButton)
            } else {
                traits.insert(.button)
            }
        case .switchControl:
            if #available(iOS 17.0, tvOS 17.0, macCatalyst 17.0, visionOS 1.0, *) {
                traits.insert([.toggleButton, .button])
            } else {
                traits.insert(.button)
            }
        case .slider:
            traits.insert(.adjustable)
        case .image:
            traits.insert(.image)
        case .link:
            traits.insert(.link)
        case .tab:
            traits.insert(.button)
        case .listItem:
            break
        case .group, .list:
            break
        default:
            break
        }
        if node.headingLevel > 0 {
            traits.insert(.header)
        }
        if !node.isEnabled {
            traits.insert(.notEnabled)
        }
        if node.isSelected || node.isChecked || node.isToggled {
            traits.insert(.selected)
        }
        if node.isLiveRegion {
            traits.insert(.updatesFrequently)
        }
        accessibilityTraits = traits

        switch node.role {
        case .list:
            accessibilityContainerType = .list
        case .tabList, .group, .dialog, .alertDialog, .radioGroup:
            accessibilityContainerType = .semanticGroup
        default:
            accessibilityContainerType = .none
        }

        // Intentionally omitted states:
        //
        // isMixed / isExpandable / isExpanded — iOS has no native
        // indeterminate or expanded traits. These require localized
        // strings via accessibilityValue; deferred until localization
        // infrastructure is added.
        //
        // readOnly / multiline — iOS conveys these structurally
        // (UITextField vs UITextView), not via accessibility traits.
        //
        // required — iOS has no "required" accessibility trait.
    }
}

#endif
