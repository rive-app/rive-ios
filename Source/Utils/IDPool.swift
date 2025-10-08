//
//  IDPool.swift
//  RiveRuntime
//
//  Created by David Skuza on 10/1/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

class IDPool<T: Hashable> {
    private var map: [T: Int32] = [:]
    private var pool: [Int32]

    init(range: Range<Int32>) {
        pool = Array(range)
    }

    func add(_ object: T) -> Int32? {
        if let id = map[object] {
            return id
        }

        guard let id = pool.popLast() else {
            return nil
        }

        map[object] = id
        return id
    }

    func remove(_ object: T) {
        guard let id = map[object] else {
            return
        }

        map[object] = nil
        pool.append(id)
    }

    func id(for object: T) -> Int32? {
        return map[object]
    }
}
