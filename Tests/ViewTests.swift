//
//  ViewTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 6/20/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

import UIKit

#if !RIVE_MAC_CATALYST // iOS tests run, Catalyst tests seem to require a running app to create a window
class ViewTests: XCTestCase {
    
    // MARK: - Window Tests

    func testIsOnscreen_WhenViewHasNoWindow_ReturnsFalse() {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenWindowIsHidden_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        let view = UIView()
        window.addSubview(view)
        window.isHidden = true
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenWindowIsVisible_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        window.isHidden = false
        
        XCTAssertTrue(view.isOnscreen())
    }
    
    // MARK: - View Visibility Tests
    
    func testIsOnscreen_WhenViewIsHidden_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        view.isHidden = true
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenViewHasEmptyBounds_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        view.frame = CGRect.zero
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenViewHasZeroAlpha_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        view.alpha = 0
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenViewIsVisible_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        view.isHidden = false
        view.alpha = 1.0
        
        XCTAssertTrue(view.isOnscreen())
    }
    
    // MARK: - Superview Visibility Tests
    
    func testIsOnscreen_WhenSuperviewIsHidden_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let superview = UIView(frame: window.bounds)
        let view = UIView(frame: superview.bounds)
        window.addSubview(superview)
        superview.addSubview(view)
        superview.isHidden = true
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenSuperviewHasEmptyBounds_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let superview = UIView(frame: window.bounds)
        let view = UIView(frame: superview.bounds)
        window.addSubview(superview)
        superview.addSubview(view)
        superview.frame = CGRect.zero
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenSuperviewHasZeroAlpha_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let superview = UIView(frame: window.bounds)
        let view = UIView(frame: superview.bounds)
        window.addSubview(superview)
        superview.addSubview(view)
        superview.alpha = 0
        
        XCTAssertFalse(view.isOnscreen())
    }

    // MARK: - ScrollView Tests

    func testIsOnscreen_WhenInScrollViewAndContentOutsideVisibleArea_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let bottomView = UIView(frame: CGRect(x: 0, y: 10, width: 10, height: 10))

        window.addSubview(scrollView)
        scrollView.addSubview(topView)
        scrollView.addSubview(bottomView)
        scrollView.contentSize = CGSize(width: 10, height: 20)
        scrollView.contentOffset = .zero

        XCTAssertFalse(bottomView.isOnscreen())
    }

    func testIsOnscreen_WhenInScrollViewAndContentInsideVisibleArea_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.isHidden = false
        window.clipsToBounds = false
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 0, y: 1, width: 10, height: 10))

        window.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(view)
        scrollView.contentSize = CGSize(width: 10, height: 10)
        scrollView.contentOffset = CGPoint.zero

        XCTAssertTrue(view.isOnscreen())
    }

    func testIsOnscreen_WhenInScrollViewAndScrolledToShowContent_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let bottomView = UIView(frame: CGRect(x: 0, y: 10, width: 10, height: 10))

        window.addSubview(scrollView)
        scrollView.addSubview(topView)
        scrollView.addSubview(bottomView)
        scrollView.contentSize = CGSize(width: 10, height: 20)
        scrollView.contentOffset = CGPoint(x: 0, y: 15)

        XCTAssertTrue(bottomView.isOnscreen())
    }

    // MARK: - Clipping and Bounds Tests
    
    func testIsOnscreen_WhenSuperviewClipsToBoundsAndViewOutsideBounds_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 20, y: 20, width: 10, height: 10))
        window.addSubview(superview)
        superview.addSubview(view)
        superview.clipsToBounds = true
        
        XCTAssertFalse(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenSuperviewClipsToBoundsAndViewInsideBounds_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 1, y: 1, width: 10, height: 10))
        window.addSubview(superview)
        superview.addSubview(view)
        superview.clipsToBounds = true
        
        XCTAssertTrue(view.isOnscreen())
    }
    
    func testIsOnscreen_WhenSuperviewDoesNotClipToBoundsAndViewOutsideBounds_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = false
        window.isHidden = false
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 20, y: 20, width: 10, height: 10))
        window.addSubview(superview)
        superview.addSubview(view)
        superview.clipsToBounds = false
        
        XCTAssertTrue(view.isOnscreen())
    }
    
    // MARK: - Complex Hierarchy Tests
    
    func testIsOnscreen_WithComplexViewHierarchy_AllVisible_ReturnsTrue() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let container1 = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let container2 = UIView(frame: CGRect(x: 1, y: 1, width: 10, height: 10))
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 2, y: 2, width: 10, height: 10))
        
        window.addSubview(container1)
        container1.addSubview(container2)
        container2.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(view)
        
        scrollView.contentSize = CGSize(width: 10, height: 10)
        scrollView.contentOffset = CGPoint.zero
        
        XCTAssertTrue(view.isOnscreen())
    }
    
    func testIsOnscreen_WithComplexViewHierarchy_OneHiddenInChain_ReturnsFalse() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        window.clipsToBounds = true
        window.isHidden = false
        let container1 = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let container2 = UIView(frame: CGRect(x: 1, y: 1, width: 10, height: 10))
        let view = UIView(frame: CGRect(x: 2, y: 2, width: 10, height: 10))
        
        window.addSubview(container1)
        container1.addSubview(container2)
        container2.addSubview(view)
        container1.isHidden = true
        
        XCTAssertFalse(view.isOnscreen())
    }
}
#endif
