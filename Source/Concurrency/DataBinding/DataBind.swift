//
//  DataBind.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/12/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "DataBind will be removed in a future release. Use a Rive initializer without dataBind, or create a state machine with explicit bindings.")
public enum DataBind: Equatable {
    /// Automatically data bind the default view model instance for a Rive object
    case auto
    /// Data bind an explicit view model instance to the state machine
    case instance(ViewModelInstance)
    /// Do not perform any data binding
    case none
}
