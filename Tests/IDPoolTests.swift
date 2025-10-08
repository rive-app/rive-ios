//
//  IDPoolTests.swift
//  RiveRuntime
//
//  Created by David Skuza on 10/1/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class IDPoolTests: XCTestCase {
    func test_pool() {
        let pool = IDPool<String>(range: 0..<2)
        XCTAssertEqual(pool.add("Hello"), 1)
        XCTAssertEqual(pool.add("Hello"), 1)
        XCTAssertEqual(pool.add("World"), 0)
        XCTAssertEqual(pool.add("World"), 0)
        XCTAssertNil(pool.add("Nil"))

        XCTAssertEqual(pool.id(for: "Hello"), 1)
        XCTAssertEqual(pool.id(for: "World"), 0)
        XCTAssertNil(pool.id(for: "Nil"))

        pool.remove("Hello")
        pool.remove("World")

        XCTAssertEqual(pool.add("Goodbye"), 0)
        XCTAssertEqual(pool.add("Moon"), 1)
        XCTAssertNil(pool.add("Another Failure"))
    }
}
