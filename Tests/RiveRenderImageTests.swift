//
//  RiveRenderImageTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 5/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

class RiveRenderImageTests: XCTestCase {
    func test_imageFromData_withEmptyData_returnsNil() {
        // Data comprised of 0 bytes
        XCTAssertNil(RiveRenderImage(data: Data()))
    }

    func test_imageFromData_withIncompatibleData_returnsNil() throws {
        // Data comprised of 8 bytes that do _not_ create an image
        XCTAssertNil(RiveRenderImage(data: Data([1, 2, 3, 4, 5, 6, 7, 8])))
    }

    func test_imageFromData_withCompatibleData_returnsImage() throws {
        let bundle = Bundle(for: type(of: self))

        // We know JPG to be a valid Rive image asset format
        var fileURL = bundle.url(forResource: "1x1_jpg", withExtension: "jpg")!
        var data = try Data(contentsOf: fileURL)
        XCTAssertNotNil(RiveRenderImage(data: data))

        // We know PNG to be a valid Rive image asset format
        fileURL = bundle.url(forResource: "1x1_png", withExtension: "png")!
        data = try Data(contentsOf: fileURL)
        XCTAssertNotNil(RiveRenderImage(data: data))
    }

    // MARK: - Extensions

    func test_imageFromUIImage_withIncorrectFormat_returnsNil() throws {
        XCTAssertNil(RiveRenderImage(image: UIImage(), format: .png))
        XCTAssertNil(RiveRenderImage(image: UIImage(), format: .jpeg(compressionQuality: 80)))
    }

    func test_imageFromUIImage_withCorrectFormat_returnsImage() throws {
        let bundle = Bundle(for: type(of: self))

        // We know JPG to be a valid Rive image asset format
        var fileURL = bundle.url(forResource: "1x1_jpg", withExtension: "jpg")!
        var data = try Data(contentsOf: fileURL)
        var image = UIImage(data: data)!
        XCTAssertNotNil(RiveRenderImage(image: image, format: .jpeg(compressionQuality: 80)))

        fileURL = bundle.url(forResource: "1x1_png", withExtension: "png")!
        data = try Data(contentsOf: fileURL)
        image = UIImage(data: data)!
        XCTAssertNotNil(RiveRenderImage(image: image, format: .png))
    }
}
