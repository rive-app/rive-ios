//
//  SemanticsDiffOperation.swift
//  RiveRuntime
//

import Foundation

/// An ordered semantic diff operation. Processing order is enforced by the
/// array returned from ``SemanticsDiff/orderedOperations``.
enum SemanticsDiffOperation {
    case removed([UInt32])
    case added([SemanticsDiffNode])
    case moved([SemanticsDiffNode])
    case childrenUpdated([SemanticsChildrenUpdate])
    case updatedSemantic([SemanticsDiffNode])
    case updatedGeometry([SemanticsBoundsUpdate])
}

extension SemanticsDiffNode {
    /// The parent node ID as a Swift optional, converting the C++ sentinel
    /// value `-1` (root) to `nil`.
    var parentNodeID: UInt32? {
        parentID < 0 ? nil : UInt32(parentID)
    }
}

extension SemanticsChildrenUpdate {
    /// The parent node ID as a Swift optional, converting the C++ sentinel
    /// value `-1` (root) to `nil`.
    var parentNodeID: UInt32? {
        parentID < 0 ? nil : UInt32(parentID)
    }
}

extension SemanticsDiff {
    /// The diff's operations in the required processing order, omitting empty categories.
    var orderedOperations: [SemanticsDiffOperation] {
        var ops: [SemanticsDiffOperation] = []
        ops.reserveCapacity(6)
        if !removed.isEmpty { ops.append(.removed(removed.map(\.uint32Value))) }
        if !added.isEmpty { ops.append(.added(Array(added))) }
        if !moved.isEmpty { ops.append(.moved(Array(moved))) }
        if !childrenUpdated.isEmpty { ops.append(.childrenUpdated(Array(childrenUpdated))) }
        if !updatedSemantic.isEmpty { ops.append(.updatedSemantic(Array(updatedSemantic))) }
        if !updatedGeometry.isEmpty { ops.append(.updatedGeometry(Array(updatedGeometry))) }
        return ops
    }
}
