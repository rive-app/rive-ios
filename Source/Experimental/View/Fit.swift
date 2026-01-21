//
//  Fit.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// An enum that defines how an artboard is scaled and positioned within its rendering bounds.
@_spi(RiveExperimental)
public enum Fit: Equatable {
    /// Scales the artboard to fill the entire bounds, potentially cropping content.
    case fill(alignment: Alignment)
    /// Scales the artboard to fit entirely within the bounds while maintaining aspect ratio.
    case contain(alignment: Alignment)
    /// Scales the artboard to cover the entire bounds while maintaining aspect ratio, potentially cropping content.
    case cover(alignment: Alignment)
    /// Scales the artboard to fit the width of the bounds while maintaining aspect ratio.
    case fitWidth(alignment: Alignment)
    /// Scales the artboard to fit the height of the bounds while maintaining aspect ratio.
    case fitHeight(alignment: Alignment)
    /// Does not scale the artboard, displaying it at its original size.
    case none(alignment: Alignment)
    /// Scales the artboard down only if it's larger than the bounds, otherwise displays at original size.
    case scaleDown(alignment: Alignment)
    /// Uses layout-based scaling with an explicit scale factor.
    case layout(scaleFactor: ScaleFactor)

    func bridged(from provider: ScaleProvider) -> (fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: CGFloat) {
        switch self {
        case .fill(let alignment):
            return (.fill, alignment.bridged(), 1)
        case .contain(let alignment):
            return (.contain, alignment.bridged(), 1)
        case .cover(let alignment):
            return (.cover, alignment.bridged(), 1)
        case .fitWidth(let alignment):
            return (.fitWidth, alignment.bridged(), 1)
        case .fitHeight(let alignment):
            return (.fitHeight, alignment.bridged(), 1)
        case .none(let alignment):
            return (.none, alignment.bridged(), 1)
        case .scaleDown(let alignment):
            return (.scaleDown, alignment.bridged(), 1)
        case .layout(let factor):
            let scaleFactor: CGFloat
            switch factor {
            case .automatic:
                if let nativeScale = provider.nativeScale {
                    scaleFactor = nativeScale
                } else {
                    scaleFactor = provider.displayScale
                }
            case .explicit(let sf):
                scaleFactor = CGFloat(sf)
            }
            return (.layout, .center, scaleFactor)
        }
    }
}

/// An enum that defines the alignment of an artboard within its rendering bounds.
@_spi(RiveExperimental)
public enum Alignment: Equatable, CaseIterable {
    /// Aligns the artboard to the top-left corner.
    case topLeft
    /// Aligns the artboard to the top-center.
    case topCenter
    /// Aligns the artboard to the top-right corner.
    case topRight
    /// Aligns the artboard to the center-left.
    case centerLeft
    /// Aligns the artboard to the center.
    case center
    /// Aligns the artboard to the center-right.
    case centerRight
    /// Aligns the artboard to the bottom-left corner.
    case bottomLeft
    /// Aligns the artboard to the bottom-center.
    case bottomCenter
    /// Aligns the artboard to the bottom-right corner.
    case bottomRight

    func bridged() -> RiveConfigurationAlignment {
        switch self {
        case .topLeft: return .topLeft
        case .topCenter: return .topCenter
        case .topRight: return .topRight
        case .centerLeft: return .centerLeft
        case .center: return .center
        case .centerRight: return .centerRight
        case .bottomLeft: return .bottomLeft
        case .bottomCenter: return .bottomCenter
        case .bottomRight: return .bottomRight
        }
    }
}

/// An enum that defines how the scale factor is determined for layout-based fitting.
@_spi(RiveExperimental)
public enum ScaleFactor: Equatable {
    /// Automatically determines the scale factor based on the display's scale.
    case automatic
    /// Uses an explicit scale factor value.
    case explicit(Float)
}
