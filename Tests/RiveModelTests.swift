//
//  RiveModelTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 7/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class RiveModelTests: XCTestCase {
    func test_volume() throws {
        let file = try RiveFile(testfileName: "multipleartboards")
        let model = RiveModel(riveFile: file)

        XCTAssertEqual(model.volume, 1)

        do {
            try model.setArtboard()

            model.volume = 0.5
            XCTAssertEqual(model.volume, 0.5)
            XCTAssertEqual(model.artboard?.__volume, 0.5)
        }

        do {
            try model.setArtboard("artboard2")

            XCTAssertEqual(model.volume, 0.5)
            XCTAssertEqual(model.artboard?.__volume, 0.5)

            model.volume = 0
            XCTAssertEqual(model.volume, 0)
            XCTAssertEqual(model.artboard?.__volume, 0)
        }
    }
}
