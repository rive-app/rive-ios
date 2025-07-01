//
//  UIView+Extensions.swift
//  RiveRuntime
//
//  Created by David Skuza on 6/20/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

#if canImport(UIKit)
private typealias Window = UIWindow
private typealias View = UIView
private typealias ScrollView = UIScrollView
#else
#if RIVE_MAC_CATALYST
private typealias Window = UIWindow
private typealias View = UIView
private typealias ScrollView = UIScrollView
#else
private typealias Window = NSWindow
private typealias View = NSView
private typealias ScrollView = NSScrollView
#endif
#endif

extension View {
    func isOnscreen() -> Bool {
        guard let window = window, isWindowHidden(window) == false, isViewHidden(self) == false else {
            return false
        }

        var currentView: View = self
        var rect = currentView.bounds
        while let superview = currentView.superview {
            guard isViewHidden(superview) == false else {
                return false
            }

            rect = currentView.convert(rect, to: superview)

            if let scrollView = superview as? ScrollView, isRectVisible(in: scrollView, rect: rect) == false {
                return false
            }

            // Test this - TL;DR: if _some_ superview clips to bounds, we might have to skip drawing
            if superview.clipsToBounds == false {
                currentView = superview
                continue
            }

            guard rect.intersects(superview.bounds) else {
                return false
            }
            
            currentView = superview
        }
        return true
    }

    private func isRectVisible(in scrollView: ScrollView, rect: CGRect) -> Bool {
        let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        return rect.intersects(visibleRect)
    }

    #if canImport(AppKit) && !RIVE_MAC_CATALYST
    private func isWindowHidden(_ window: NSWindow) -> Bool {
        return window.contentView?.bounds.isEmpty == true || window.isVisible == false || window.alphaValue == 0
    }
    #else
    private func isWindowHidden(_ window: Window) -> Bool {
        return isViewHidden(window)
    }
    #endif

    private func isViewHidden(_ view: View) -> Bool {
        return view.bounds.isEmpty || view.isHidden || view.alpha == 0
    }
}

#if canImport(AppKit) && !RIVE_MAC_CATALYST
extension View {
    var alpha: CGFloat {
        guard let opacity = layer?.opacity else { return 0 }
        return CGFloat(opacity)
    }
}

extension ScrollView {
    var contentOffset: CGPoint {
        return bounds.origin
    }
}
#endif
