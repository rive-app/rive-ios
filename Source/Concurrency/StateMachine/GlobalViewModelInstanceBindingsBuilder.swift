//
//  GlobalViewModelInstanceBindingsBuilder.swift
//  RiveRuntime
//
//  Created by Rive on 7/29/26.
//  Copyright © 2026 Rive. All rights reserved.
//

/// Builds named global view model instance bindings.
///
/// Each expression is a `(name, instance)` tuple. Conditionals, optional branches, and loops can
/// be used to select bindings at runtime.
@resultBuilder
public enum GlobalViewModelInstanceBindingsBuilder {
    public static func buildBlock(_ components: [(String, ViewModelInstance)]...) -> [(String, ViewModelInstance)] {
        return components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: (String, ViewModelInstance)) -> [(String, ViewModelInstance)] {
        return [expression]
    }

    public static func buildOptional(_ component: [(String, ViewModelInstance)]?) -> [(String, ViewModelInstance)] {
        return component ?? []
    }

    public static func buildEither(first component: [(String, ViewModelInstance)]) -> [(String, ViewModelInstance)] {
        return component
    }

    public static func buildEither(second component: [(String, ViewModelInstance)]) -> [(String, ViewModelInstance)] {
        return component
    }

    public static func buildArray(_ components: [[(String, ViewModelInstance)]]) -> [(String, ViewModelInstance)] {
        return components.flatMap { $0 }
    }

    static func validate(_ bindings: [(String, ViewModelInstance)]) throws {
        var validation = Set<String>()

        for (name, _) in bindings {
            guard validation.insert(name).inserted else {
                throw StateMachineError.duplicateGlobalViewModelInstance(name)
            }
        }
    }
}
