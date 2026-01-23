//
//  RiveFallbackFontDescriptor.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/9/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import SwiftUI

/// An enumeration of system design values available when creating a font based on a (system) font.
@objc public enum RiveFallbackFontDescriptorDesign: Int {
    /// Defaults to the iOS (system) font design; sans-serif on the latest versions of iOS.
    case `default` = 0
    /// The rounded variant of `default`.
    case rounded = 1
    /// The monospaced variant of `default`.
    case monospaced = 2
    /// The serif variant of `default`.
    case serif = 3
}

/// An enuimeration of font weight values available when creating a font based on a (system) font.
@objc public enum RiveFallbackFontDescriptorWeight: Int {
    /// The ultra-light font weight.
    case ultraLight = 0
    /// The thin font weight.
    case thin = 1
    /// The light font weight.
    case light = 2
    /// The regular (typically default) font weight.
    case regular = 3
    /// The medium font weight.
    case medium = 4
    /// The semi-bold font weight.
    case semibold = 5
    /// The bold font weight.
    case bold = 6
    /// The heavy font weight.
    case heavy = 7
    /// The black font weight.
    case black = 8
}

@objc public enum RiveFallbackFontDescriptorWidth: Int {
    /// A width that compresses a font.
    case compressed = 0
    /// A width that condenses a font.
    case condensed = 1
    /// The standard width of a font.
    case standard = 2
    /// The expanded width of a font.
    case expanded = 3

    public var defaultFloatValue: CGFloat {
        // These default values are generated from logging
        // system fonts at various values. - David
        switch self {
        case .compressed: return -0.3
        case .condensed: return -0.2
        case .standard: return 0
        case .expanded: return 0.2
        }
    }
}

/// A type that represents the description of a font, based on a system font.
@objc public class RiveFallbackFontDescriptor: NSObject {
    /// The system design of the font.
    let design: RiveFallbackFontDescriptorDesign
    /// The weight of the font.
    let weight: RiveFallbackFontDescriptorWeight
    /// The width of the font. This value is not guaranteed to be available for all fonts.
    let width: RiveFallbackFontDescriptorWidth
    // Whether or not the descriptor can use suggested fonts if necessary
    public let allowsSuggestedFonts: Bool

    /// Initializes a new font descriptor, used to generate a font based on a system font.
    /// - Parameters:
    ///   - design: The design of the font.
    ///   - weight: The weight of the font.
    ///   - width: The width of the font. This value is not guaranteed to be available for all fonts.
    @objc public init(
        design: RiveFallbackFontDescriptorDesign = .default,
        weight: RiveFallbackFontDescriptorWeight = .regular,
        width: RiveFallbackFontDescriptorWidth = .standard,
        allowsSuggestedFonts: Bool = true
    ) {
        self.design = design
        self.weight = weight
        self.width = width
        self.allowsSuggestedFonts = allowsSuggestedFonts
    }
}
