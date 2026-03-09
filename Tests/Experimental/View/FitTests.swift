//
//  FitTests.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class FitTests: XCTestCase {
    @MainActor
    struct MockScaleProvider: ScaleProvider {
        let nativeScale: CGFloat?
        let displayScale: CGFloat
        
        init(nativeScale: CGFloat? = nil, displayScale: CGFloat = 1.0) {
            self.nativeScale = nativeScale
            self.displayScale = displayScale
        }
    }
    
    func test_alignment_bridged() {
        for alignment in Alignment.allCases {
            let result = alignment.bridged()
            switch alignment {
            case .topLeft: XCTAssertEqual(result, .topLeft)
            case .topCenter: XCTAssertEqual(result, .topCenter)
            case .topRight: XCTAssertEqual(result, .topRight)
            case .centerLeft: XCTAssertEqual(result, .centerLeft)
            case .center: XCTAssertEqual(result, .center)
            case .centerRight: XCTAssertEqual(result, .centerRight)
            case .bottomLeft: XCTAssertEqual(result, .bottomLeft)
            case .bottomCenter: XCTAssertEqual(result, .bottomCenter)
            case .bottomRight: XCTAssertEqual(result, .bottomRight)
            }
        }
    }

    @MainActor
    func test_fit_bridged() {
        let provider = MockScaleProvider()
        
        for alignment in Alignment.allCases {
            var result = Fit.fill(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .fill)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.contain(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .contain)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.cover(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .cover)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.fitWidth(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .fitWidth)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.fitHeight(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .fitHeight)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.none(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .none)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
            
            result = Fit.scaleDown(alignment: alignment).bridged(from: provider)
            XCTAssertEqual(result.fit, .scaleDown)
            XCTAssertEqual(result.alignment, alignment.bridged())
            XCTAssertEqual(result.scaleFactor, 1.0)
        }
    }

    @MainActor
    func test_fit_bridged_layout() {
        let nativeScale: CGFloat = 2.5
        let displayScale: CGFloat = 3.0
        let providerWithNativeScale = MockScaleProvider(nativeScale: nativeScale, displayScale: displayScale)
        var result = Fit.layout(scaleFactor: .automatic).bridged(from: providerWithNativeScale)
        XCTAssertEqual(result.fit, .layout)
        XCTAssertEqual(result.alignment, .center)
        XCTAssertEqual(result.scaleFactor, nativeScale, accuracy: 0.0001)
        
        let providerWithoutNativeScale = MockScaleProvider(nativeScale: nil, displayScale: displayScale)
        result = Fit.layout(scaleFactor: .automatic).bridged(from: providerWithoutNativeScale)
        XCTAssertEqual(result.fit, .layout)
        XCTAssertEqual(result.alignment, .center)
        XCTAssertEqual(result.scaleFactor, displayScale, accuracy: 0.0001)
        
        let explicitScale: Float = 1.75
        result = Fit.layout(scaleFactor: .explicit(explicitScale)).bridged(from: providerWithNativeScale)
        XCTAssertEqual(result.fit, .layout)
        XCTAssertEqual(result.alignment, .center)
        XCTAssertEqual(result.scaleFactor, CGFloat(explicitScale), accuracy: 0.0001)
    }
    
}
