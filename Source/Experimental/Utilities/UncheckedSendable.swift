//
//  UncheckedSendable.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/11/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation

struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
}
