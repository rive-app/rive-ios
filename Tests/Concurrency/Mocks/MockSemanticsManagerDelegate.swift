//
//  MockSemanticsManagerDelegate.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 4/23/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

#if !os(macOS) || RIVE_MAC_CATALYST

class MockSemanticsManagerDelegate: SemanticsManagerDelegate {
    var focusedNodeIDs: [UInt32] = []
    var firedActions: [(nodeID: UInt32, actionType: SemanticActionType)] = []
    var container: AnyObject = NSObject()
    var displayScale: CGFloat = 1.0
    var commitDiffsCount: Int = 0
    var lastCommitFocusedElement: SemanticsElement?
    var lastCommitIsModal: Bool = false
    var clearFocusCount: Int = 0

    func manager(_ manager: SemanticsManager, didRequestFocusForNodeID nodeID: UInt32) {
        focusedNodeIDs.append(nodeID)
    }

    func manager(_ manager: SemanticsManager, didFireAction actionType: SemanticActionType, forNodeID nodeID: UInt32) {
        firedActions.append((nodeID: nodeID, actionType: actionType))
    }

    func manager(_ manager: SemanticsManager, didCommitDiffsWithFocusedElement element: SemanticsElement?, isModal: Bool) {
        commitDiffsCount += 1
        lastCommitFocusedElement = element
        lastCommitIsModal = isModal
    }

    func managerDidRequestClearFocus(_ manager: SemanticsManager) {
        clearFocusCount += 1
    }

    func accessibilityContainerForManager(_ manager: SemanticsManager) -> AnyObject {
        container
    }

    func displayScaleForManager(_ manager: SemanticsManager) -> CGFloat {
        displayScale
    }
}

#endif
