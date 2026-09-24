//
//  WeakReference.swift
//  RiveRuntime
//
//  Created by Rive on 8/5/26.
//  Copyright © 2026 Rive. All rights reserved.
//

final class WeakReference<Value: AnyObject> {
    weak var value: Value?

    init(_ value: Value?) {
        self.value = value
    }
}
