//
//  SemanticsManager.swift
//  RiveRuntime
//
//  Created by David Skuza on 4/21/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

// MARK: - SemanticsManagerDelegate

/// Delegate for semantic events that require state machine interaction.
/// Conformed to by the controller to keep the manager decoupled from
/// the state machine.
@MainActor
protocol SemanticsManagerDelegate: AnyObject {
    /// Requests that the state machine move semantic focus to the given node.
    func manager(_ manager: SemanticsManager, didRequestFocusForNodeID nodeID: UInt32)
    /// Fires a semantic action (tap, increment, decrement) on the given node.
    func manager(_ manager: SemanticsManager, didFireAction actionType: SemanticActionType, forNodeID nodeID: UInt32)
    /// Called when VoiceOver focus leaves the Rive view entirely.
    func managerDidRequestClearFocus(_ manager: SemanticsManager)
    /// Called after diffs are committed, with the element VoiceOver should focus
    /// and whether a modal dialog is active.
    func manager(_ manager: SemanticsManager, didCommitDiffsWithFocusedElement element: SemanticsElement?, isModal: Bool)
    /// Returns the view that owns the accessibility elements.
    func accessibilityContainerForManager(_ manager: SemanticsManager) -> AnyObject
    /// Returns the current display scale, used to convert pixel bounds to points.
    func displayScaleForManager(_ manager: SemanticsManager) -> CGFloat
}

// MARK: - SemanticsManager

/// Converts incremental semantic diffs from the C++ runtime into
/// `UIAccessibilityElement` objects for VoiceOver.
///
/// Maintains a flat node dictionary (for O(1) diff lookups) and a parallel
/// element dictionary (for UIKit). The ordered element array is rebuilt via
/// depth-first walk only when the tree structure changes.
@MainActor
class SemanticsManager {
    /// Delegate notified for events requiring state machine interaction.
    /// Also provides the accessibility container and display scale.
    weak var delegate: SemanticsManagerDelegate?

    /// All semantic nodes keyed by ID. Includes nodes of every role
    /// (not just text) because non-text nodes still participate in tree
    /// structure and children arrays.
    private var nodes: [UInt32: SemanticsNode] = [:]
    /// Accessibility elements keyed by node ID. Only contains elements
    /// for nodes that pass ``SemanticsNode/isAccessibilityVisible``.
    private var elements: [UInt32: SemanticsElement] = [:]
    /// The root node ID from the most recent diff. Used as the starting
    /// point for the depth-first walk that builds ``orderedElements``.
    private var rootID: UInt32 = 0
    /// Top-level child IDs from a `childrenUpdated` with `parentID: -1`.
    /// Used as walk starting points when `rootID` refers to an implicit
    /// root that doesn't exist in ``nodes``.
    private var rootChildren: [UInt32] = []
    /// Cached depth-first ordered array of elements. Rebuilt lazily when
    /// ``isOrderingDirty`` is true.
    private var orderedElements: [SemanticsElement] = []
    /// Set to true when any diff operation requires a full rebuild
    /// (structure changes, visibility transitions, container geometry
    /// updates, or semantic updates with visible elements).
    /// Non-container geometry-only updates use incremental frame updates.
    private var isOrderingDirty = false
    /// Pending diffs queued by ``enqueue(diff:)`` and flushed by ``commitDiffs()``.
    private var pendingDiffs: [SemanticsDiff] = []
    /// The element most recently focused by VoiceOver. Used to maintain
    /// focus continuity when posting `.layoutChanged` notifications.
    private weak var lastFocusedElement: SemanticsElement?
    /// The element that was focused before a modal dialog appeared.
    /// Restored as the focus target when the modal is dismissed.
    private weak var preModalFocusedElement: SemanticsElement?
    /// Whether a modal dialog was active after the last commit.
    private var wasModal = false

    init(delegate: SemanticsManagerDelegate) {
        self.delegate = delegate
    }

    private var modalElement: SemanticsElement? {
        elements.values.first { nodes[$0.nodeID]?.isModal == true }
    }

    /// The ordered list of accessibility elements for VoiceOver.
    ///
    /// Triggers a depth-first ordering rebuild if the tree structure changed
    /// since the last access. Otherwise returns the cached array.
    ///
    /// When a modal dialog is present, returns only the modal element and
    /// its children to trap VoiceOver focus within the dialog.
    var accessibilityElements: [SemanticsElement] {
        if isOrderingDirty {
            isOrderingDirty = false
            rebuildOrderedElements()
        }
        if let modal = modalElement {
            return [modal]
        }
        return orderedElements
    }

    /// Queues a diff for later application by ``commitDiffs()``.
    func enqueue(diff: SemanticsDiff) {
        pendingDiffs.append(diff)
    }

    /// Applies all queued diffs and notifies the delegate.
    ///
    /// A focused element is always resolved and forwarded to the delegate:
    /// entering a modal saves the current element and focuses the modal's
    /// first child; leaving a modal restores the pre-modal element;
    /// otherwise ``lastFocusedElement`` is passed for continuity.
    ///
    /// The delegate is only notified when the diff batch contains
    /// accessibility-meaningful changes (structure, semantic content, or
    /// container geometry) or a modal transition occurs.  Non-container
    /// geometry updates are applied silently because their frames are
    /// updated incrementally and VoiceOver queries them lazily.
    func commitDiffs() {
        guard !pendingDiffs.isEmpty else { return }
        let diffs = pendingDiffs
        pendingDiffs.removeAll(keepingCapacity: true)
        var hasAccessibilityChanges = false
        for diff in diffs {
            if applyDiff(diff) {
                hasAccessibilityChanges = true
            }
        }

        let isModal = modalElement != nil
        let modalTransitioned = wasModal != isModal

        let focusedElement: SemanticsElement?
        if !wasModal && isModal {
            preModalFocusedElement = lastFocusedElement
            let modal = accessibilityElements.first
            focusedElement = modal?.childElements?.first ?? modal
        } else if wasModal && !isModal {
            if let preModalFocusedElement, elements[preModalFocusedElement.nodeID] != nil {
                focusedElement = preModalFocusedElement
            } else {
                focusedElement = nil
            }
            preModalFocusedElement = nil
        } else if let lastFocusedElement, elements[lastFocusedElement.nodeID] != nil {
            focusedElement = lastFocusedElement
        } else {
            focusedElement = nil
        }
        wasModal = isModal

        guard hasAccessibilityChanges || modalTransitioned else { return }
        delegate?.manager(self, didCommitDiffsWithFocusedElement: focusedElement, isModal: isModal)
    }

    /// Applies an incremental diff to the internal node tree and updates
    /// the accessibility elements accordingly.
    ///
    /// Returns `true` if any operation other than a non-container
    /// geometry-only update was present, indicating an
    /// accessibility-meaningful change.
    @discardableResult
    private func applyDiff(_ diff: SemanticsDiff) -> Bool {
        rootID = diff.rootID

        var hasAccessibilityChanges = false
        for operation in diff.orderedOperations {
            switch operation {
            case .removed(let nodeIDs):
                applyRemoved(nodeIDs)
                hasAccessibilityChanges = true
            case .added(let diffNodes):
                applyAdded(diffNodes)
                hasAccessibilityChanges = true
            case .moved(let diffNodes):
                applyMoved(diffNodes)
                hasAccessibilityChanges = true
            case .childrenUpdated(let updates):
                applyChildrenUpdated(updates)
                hasAccessibilityChanges = true
            case .updatedSemantic(let diffNodes):
                if applyUpdatedSemantic(diffNodes) {
                    hasAccessibilityChanges = true
                }
            case .updatedGeometry(let updates):
                if applyUpdatedGeometry(updates) {
                    hasAccessibilityChanges = true
                }
            }
        }
        return hasAccessibilityChanges
    }

    // MARK: - Diff Operations

    private func applyRemoved(_ nodeIDs: [UInt32]) {
        for nodeID in nodeIDs {
            nodes.removeValue(forKey: nodeID)
            elements.removeValue(forKey: nodeID)
        }
        isOrderingDirty = true
    }

    private func applyAdded(_ diffNodes: [SemanticsDiffNode]) {
        for diffNode in diffNodes {
            let node = SemanticsNode(from: diffNode)
            nodes[node.nodeID] = node
            if node.isAccessibilityVisible {
                let element = SemanticsElement(nodeID: node.nodeID, accessibilityContainer: delegate?.accessibilityContainerForManager(self) ?? NSObject(), delegate: self)
                element.configure(from: node)

                elements[node.nodeID] = element
            }
        }
        isOrderingDirty = true
    }

    private func applyMoved(_ diffNodes: [SemanticsDiffNode]) {
        for diffNode in diffNodes {
            let existingChildren = nodes[diffNode.nodeID]?.children ?? []
            let node = SemanticsNode(from: diffNode, children: existingChildren)
            nodes[node.nodeID] = node

            let wasVisible = elements[node.nodeID] != nil
            let isVisible = node.isAccessibilityVisible

            if wasVisible && isVisible {
                elements[node.nodeID]?.configure(from: node)
            } else if wasVisible && !isVisible {
                elements.removeValue(forKey: node.nodeID)
            } else if !wasVisible && isVisible {
                let element = SemanticsElement(nodeID: node.nodeID, accessibilityContainer: delegate?.accessibilityContainerForManager(self) ?? NSObject(), delegate: self)
                element.configure(from: node)
                elements[node.nodeID] = element
            }
        }
        isOrderingDirty = true
    }

    private func applyChildrenUpdated(_ updates: [SemanticsChildrenUpdate]) {
        for update in updates {
            let childIDs = update.childIDs.map(\.uint32Value)

            // parentID -1 (nil) describes root-level node ordering, not a
            // parent-child edge. Store these IDs for the walk to use when
            // rootID refers to an implicit root not present in nodes.
            guard let parentID = update.parentNodeID else {
                rootChildren = childIDs
                continue
            }
            guard let existingNode = nodes[parentID] else { continue }
            nodes[parentID] = existingNode.withChildren(childIDs)
        }
        isOrderingDirty = true
    }

    @discardableResult
    private func applyUpdatedSemantic(_ diffNodes: [SemanticsDiffNode]) -> Bool {
        var hadAccessibilityChange = false
        for diffNode in diffNodes {
            let oldNode = nodes[diffNode.nodeID]
            let existingChildren = oldNode?.children ?? []
            let node = SemanticsNode(from: diffNode, children: existingChildren)
            nodes[node.nodeID] = node

            let wasVisible = elements[node.nodeID] != nil
            let isVisible = node.isAccessibilityVisible

            if wasVisible && isVisible {
                elements[node.nodeID]?.configure(from: node)
                hadAccessibilityChange = true
                if oldNode?.isContainer != node.isContainer {
                    isOrderingDirty = true
                }
            } else if wasVisible && !isVisible {
                elements.removeValue(forKey: node.nodeID)
                isOrderingDirty = true
                hadAccessibilityChange = true
            } else if !wasVisible && isVisible {
                let element = SemanticsElement(nodeID: node.nodeID, accessibilityContainer: delegate?.accessibilityContainerForManager(self) ?? NSObject(), delegate: self)
                element.configure(from: node)

                elements[node.nodeID] = element
                isOrderingDirty = true
                hadAccessibilityChange = true
            }
        }
        return hadAccessibilityChange
    }

    @discardableResult
    private func applyUpdatedGeometry(_ updates: [SemanticsBoundsUpdate]) -> Bool {
        var hadLayoutChange = false
        var frameUpdates: [(SemanticsElement, SemanticsNode)] = []
        for update in updates {
            guard let existingNode = nodes[update.nodeID] else { continue }
            let newBounds = CGRect(
                x: CGFloat(update.minX),
                y: CGFloat(update.minY),
                width: CGFloat(update.maxX - update.minX),
                height: CGFloat(update.maxY - update.minY)
            )
            let node = existingNode.withBounds(newBounds)
            nodes[node.nodeID] = node

            let wasVisible = elements[node.nodeID] != nil
            let isVisible = node.isAccessibilityVisible

            if wasVisible && isVisible {
                if node.isContainer {
                    isOrderingDirty = true
                    hadLayoutChange = true
                } else if let element = elements[node.nodeID] {
                    frameUpdates.append((element, node))
                }
            } else if wasVisible && !isVisible {
                elements.removeValue(forKey: node.nodeID)
                isOrderingDirty = true
                hadLayoutChange = true
            } else if !wasVisible && isVisible {
                let element = SemanticsElement(nodeID: node.nodeID, accessibilityContainer: delegate?.accessibilityContainerForManager(self) ?? NSObject(), delegate: self)
                element.configure(from: node)
                elements[node.nodeID] = element
                isOrderingDirty = true
                hadLayoutChange = true
            }
        }

        if !frameUpdates.isEmpty && !isOrderingDirty {
            let scale = delegate?.displayScaleForManager(self) ?? 1.0
            for (element, node) in frameUpdates {
                updateElementFrame(element, node: node, scale: scale)
            }
        }

        return hadLayoutChange
    }

    private func updateElementFrame(
        _ element: SemanticsElement,
        node: SemanticsNode,
        scale: CGFloat
    ) {
        let absoluteFrame = CGRect(
            x: node.bounds.minX / scale,
            y: node.bounds.minY / scale,
            width: node.bounds.width / scale,
            height: node.bounds.height / scale
        )

        if let containerElement = element.accessibilityContainer as? SemanticsElement,
           let containerNode = nodes[containerElement.nodeID] {
            let containerFrame = CGRect(
                x: containerNode.bounds.minX / scale,
                y: containerNode.bounds.minY / scale,
                width: containerNode.bounds.width / scale,
                height: containerNode.bounds.height / scale
            )
            element.accessibilityFrameInContainerSpace = CGRect(
                x: absoluteFrame.origin.x - containerFrame.origin.x,
                y: absoluteFrame.origin.y - containerFrame.origin.y,
                width: absoluteFrame.width,
                height: absoluteFrame.height
            )
        } else {
            element.accessibilityFrameInContainerSpace = absoluteFrame
        }
    }

    // MARK: - Tree Walk

    /// Rebuilds the ordered elements array via a depth-first walk from the root.
    ///
    /// Container elements (e.g. tabList) get their ``SemanticsElement/childElements``
    /// populated with nested child elements. Only root-level elements appear in
    /// ``orderedElements``; nested elements live inside their container's
    /// `childElements` array instead.
    private func rebuildOrderedElements() {
        for element in elements.values {
            element.childElements = nil
        }
        var result: [SemanticsElement] = []
        result.reserveCapacity(elements.count)
        let scale = delegate?.displayScaleForManager(self) ?? 1.0

        let topLevelContainer = delegate?.accessibilityContainerForManager(self) ?? NSObject()
        if nodes[rootID] != nil {
            depthFirstCollect(nodeID: rootID, into: &result, scale: scale, parentContainer: topLevelContainer)
        } else {
            for childID in rootChildren {
                depthFirstCollect(nodeID: childID, into: &result, scale: scale, parentContainer: topLevelContainer)
            }
        }
        orderedElements = result
    }

    private func depthFirstCollect(
        nodeID: UInt32,
        into result: inout [SemanticsElement],
        scale: CGFloat,
        containerFrame: CGRect = .zero,
        parentContainer: AnyObject
    ) {
        guard let node = nodes[nodeID] else { return }
        let element = elements[nodeID]

        if let element {
            element.accessibilityContainer = parentContainer

            let absoluteFrame = CGRect(
                x: node.bounds.minX / scale,
                y: node.bounds.minY / scale,
                width: node.bounds.width / scale,
                height: node.bounds.height / scale
            )

            if containerFrame != .zero {
                element.accessibilityFrameInContainerSpace = CGRect(
                    x: absoluteFrame.origin.x - containerFrame.origin.x,
                    y: absoluteFrame.origin.y - containerFrame.origin.y,
                    width: absoluteFrame.width,
                    height: absoluteFrame.height
                )
            } else {
                element.accessibilityFrameInContainerSpace = absoluteFrame
            }

            if node.isContainer {
                var children: [SemanticsElement] = []
                for childID in node.children {
                    depthFirstCollect(nodeID: childID, into: &children, scale: scale, containerFrame: absoluteFrame, parentContainer: element)
                }
                element.childElements = children.isEmpty ? nil : children
                result.append(element)
                return
            } else {
                result.append(element)
                // Non-container nodes with a semantic role absorb their
                // children (e.g. a tab that flattens child text labels).
                // Structural (.none) nodes are pass-through — they create
                // an element for themselves but still walk children.
                if node.role != .none {
                    return
                }
            }
        }

        for childID in node.children {
            depthFirstCollect(nodeID: childID, into: &result, scale: scale, containerFrame: containerFrame, parentContainer: parentContainer)
        }
    }
}

// MARK: - SemanticsManager + SemanticsElementDelegate

extension SemanticsManager: SemanticsElementDelegate {
    func elementDidBecomeFocused(_ element: SemanticsElement) {
        lastFocusedElement = element
        guard let node = nodes[element.nodeID], node.isFocusable else { return }
        delegate?.manager(self, didRequestFocusForNodeID: node.nodeID)
    }

    func elementDidLoseFocus(_ element: SemanticsElement) {
        guard element === lastFocusedElement else { return }
        lastFocusedElement = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard self.lastFocusedElement == nil else { return }
            self.delegate?.managerDidRequestClearFocus(self)
        }
    }

    func elementDidActivate(_ element: SemanticsElement) -> Bool {
        guard let node = nodes[element.nodeID],
              node.isEnabled,
              node.availableActions.contains(.tap) else { return false }
        delegate?.manager(self, didFireAction: .tap, forNodeID: node.nodeID)
        return true
    }

    func elementDidIncrement(_ element: SemanticsElement) {
        guard let node = nodes[element.nodeID],
              node.isEnabled,
              node.availableActions.contains(.increase) else { return }
        delegate?.manager(self, didFireAction: .increase, forNodeID: node.nodeID)
    }

    func elementDidDecrement(_ element: SemanticsElement) {
        guard let node = nodes[element.nodeID],
              node.isEnabled,
              node.availableActions.contains(.decrease) else { return }
        delegate?.manager(self, didFireAction: .decrease, forNodeID: node.nodeID)
    }
}

#endif
