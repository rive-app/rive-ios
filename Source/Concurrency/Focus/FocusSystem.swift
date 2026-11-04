//
//  FocusSystem.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/10/26.
//  Copyright © 2026 Rive. All rights reserved.
//

/// A direction for sequential traversal through authored Rive focus nodes.
enum FocusTraversalDirection {
    /// Traverses toward the next authored focus node.
    case next
    /// Traverses toward the previous authored focus node.
    case previous
}

/// Receives platform focus events that require Rive behavior.
///
/// A ``FocusSystem`` translates platform-specific focus callbacks into this
/// platform-independent contract. The delegate reports whether Rive consumed
/// the traversal request.
@MainActor
protocol FocusSystemDelegate: AnyObject {
    #if os(tvOS)
    /// Attempts spatial navigation before tvOS moves native focus elsewhere.
    func focusSystem(_ focusSystem: any FocusSystem, moveIn direction: StateMachine.FocusDirection) -> Bool
    #endif

    /// Notifies the delegate that native focus left the Rive focus environment.
    ///
    /// The delegate should clear any focus retained by the Rive state machine.
    func focusSystemDidExit(_ focusSystem: any FocusSystem)

    /// Reports committed native entry. A missing direction represents entry
    /// without sequential navigation; the controller preserves existing focus.
    /// - Returns: `false` only when attempted sequential entry was unconsumed,
    ///   allowing platforms that support it to continue native traversal.
    @discardableResult
    func focusSystem(
        _ focusSystem: any FocusSystem,
        didEnter direction: FocusTraversalDirection?
    ) -> Bool
}

/// Adapts a platform focus system to Rive's generic focus controller.
///
/// Concrete implementations interpret platform focus updates and forward Rive
/// behavior through a ``FocusSystemDelegate``. Runtime operations remain owned
/// by the delegate rather than the platform adapter.
@MainActor
protocol FocusSystem: AnyObject {
    /// The object that handles Rive focus behavior.
    var delegate: (any FocusSystemDelegate)? { get set }

    /// Whether the platform should include the Rive view in native focus
    /// traversal.
    var isFocusable: Bool { get set }

    /// The platform's traversal direction for native entry without navigation.
    /// A missing direction preserves the graphic's focus without selecting a node.
    var defaultEntryDirection: FocusTraversalDirection? { get }

    /// Permanently disables the adapter so it ignores subsequent focus events.
    func invalidate()
}
