//
//  RiveFallbackFontDescriptor+UIKit.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/9/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
public typealias RiveNativeFont = UIFont
private typealias RiveNativeFontDescriptor = UIFontDescriptor
#elseif os(macOS)
import AppKit
public typealias RiveNativeFont = NSFont
private typealias RiveNativeFontDescriptor = NSFontDescriptor
#endif

private typealias RiveNativeFontWeight = RiveNativeFont.Weight
private typealias RiveNativeFontDesign = RiveNativeFontDescriptor.SystemDesign

@available(iOS 16, macOS 13, *)
private typealias RiveNativeFontWidth = RiveNativeFont.Width

extension RiveNativeFontDesign {
    /// Initializes a SystemDesign, 1:1 mapped from a `RiveFontDescriptionSystemDesign`
    init(_ design: RiveFallbackFontDescriptorDesign) {
        switch design {
        case .default: self.init(rawValue: Self.default.rawValue)
        case .rounded: self.init(rawValue: Self.rounded.rawValue)
        case .monospaced: self.init(rawValue: Self.monospaced.rawValue)
        case .serif: self.init(rawValue: Self.serif.rawValue)
        }
    }
}

extension RiveNativeFontWeight {
    /// Initializes a Weight, 1:1 mapped from a `RiveFallbackFontDescriptionWeight`
    init(_ weight: RiveFallbackFontDescriptorWeight) {
        switch weight {
        case .ultraLight: self.init(rawValue: Self.ultraLight.rawValue)
        case .thin: self.init(rawValue: Self.thin.rawValue)
        case .light: self.init(rawValue: Self.light.rawValue)
        case .regular: self.init(rawValue: Self.regular.rawValue)
        case .medium: self.init(rawValue: Self.medium.rawValue)
        case .semibold: self.init(rawValue: Self.semibold.rawValue)
        case .bold: self.init(rawValue: Self.bold.rawValue)
        case .heavy: self.init(rawValue: Self.heavy.rawValue)
        case .black: self.init(rawValue: Self.black.rawValue)
        }
    }

    /// Initializes a Weight, translated from a font trait describing its UI usage
    fileprivate init(_ usage: RiveFallbackFontUIUsage) {
        switch usage {
        case .ultraLight: self.init(rawValue: Self.ultraLight.rawValue)
        case .thin: self.init(rawValue: Self.thin.rawValue)
        case .light: self.init(rawValue: Self.light.rawValue)
        case .regular: self.init(rawValue: Self.regular.rawValue)
        case .medium: self.init(rawValue: Self.medium.rawValue)
        case .semibold: self.init(rawValue: Self.semibold.rawValue)
        case .bold: self.init(rawValue: Self.bold.rawValue)
        case .heavy: self.init(rawValue: Self.heavy.rawValue)
        case .black: self.init(rawValue: Self.black.rawValue)
        }
    }
}

@available(iOS 16, macOS 13, *)
extension RiveNativeFontWidth {
    /// Initialized a Width, 1:1 mapped from a `RiveFallbackFontDescriptorWeight`
    init(_ width: RiveFallbackFontDescriptorWidth) {
        switch width {
        case .compressed: self.init(rawValue: Self.compressed.rawValue)
        case .condensed: self.init(rawValue: Self.condensed.rawValue)
        case .standard: self.init(rawValue: Self.standard.rawValue)
        case .expanded: self.init(rawValue: Self.expanded.rawValue)
        }
    }
}

extension RiveFallbackFontDescriptor: RiveFallbackFontProvider {
    /// The default font size to use when generating a system font. Due to how Rive renders text, this value
    /// is essentially unused, and the font drawn will be sized to match the text run.
    private static let defaultFontSize: CGFloat = 20

    /// The default font to use when generating fonts from a `RiveFallbackFontDescriptor`.
    /// - Returns: A native Apple font with the set system design, size, and weight.
    private func defaultSystemFont() -> RiveNativeFont {
        return RiveNativeFont.systemFont(ofSize: Self.defaultFontSize, weight: .init(weight))
    }

    /// - Returns: The native Apple font descriptor created from the `RiveFallbackFontDescriptor`.
    private func toFontDescriptor() -> RiveNativeFontDescriptor {
        let systemDescriptor = defaultSystemFont().fontDescriptor
        // .withDesign only works if based off of a system font
        guard var updatedDescriptor = systemDescriptor.withDesign(RiveNativeFontDesign(design)) else {
            return systemDescriptor
        }

        // In iOS 16+, there is an API to generate a system font with a given width.
        // However, iOS seems to generate an incorrect font for some design / weight / width variations.
        // The "best" experience has been by first obtaining a font, ignoring weight, then
        // updating the weight after the (hopefully) correct font has been generated.
        if var traits = updatedDescriptor.object(forKey: .traits) as? [RiveNativeFontDescriptor.TraitKey: Any] {
            if #available(iOS 16, macOS 13, *) {
                /// iOS 16+ / macOS 13+ provide native width values; these supercede the default values as described in `RiveFallbackFontDescriptorWidth`
                traits[.width] = RiveNativeFontWidth(width).rawValue
                updatedDescriptor = updatedDescriptor.addingAttributes([.traits: traits])
            } else {
                traits[.width] = width.defaultFloatValue
                updatedDescriptor = updatedDescriptor.addingAttributes([.traits: traits])
            }
        }

        return updatedDescriptor
    }

    /// - Returns: The font generated from all values of a `RiveFallbackFontDescriptor`.
    @objc public var fallbackFont: RiveNativeFont {
        let font: RiveNativeFont?
        #if os(iOS)
            font = RiveNativeFont(descriptor: toFontDescriptor(), size: Self.defaultFontSize)
        #elseif os(macOS)
            font = RiveNativeFont(descriptor: toFontDescriptor(), size: Self.defaultFontSize)
        #endif
        guard let font = font else {
            return defaultSystemFont()
        }
        return font
    }
}

// Allows UIFont/NSFont to be used as a provider for fallback fonts,
// in addition to RiveFallbackFontDescriptor.
@objc extension RiveNativeFont: RiveFallbackFontProvider {
    /// The native font returned that can be used as a fallback font. In this instance, the native font itself can be used.
    public var fallbackFont: RiveNativeFont {
        return self
    }
}

/// An enumeration of all possible usages of fonts within UI elements. They mirror the various available native font weights.
/// - Note: These values have been obtained by logging the font descriptors of various system fonts.
enum RiveFallbackFontUIUsage: String {
    case ultraLight = "CTFontUltraLightUsage"
    case thin = "CTFontThinUsage"
    case light = "CTFontLightUsage"
    case regular = "CTFontRegularUsage"
    case medium = "CTFontMediumUsage"
    case semibold = "CTFontDemiUsage"
    case bold = "CTFontBoldUsage"
    case heavy = "CTFontHeavyUsage"
    case black = "CTFontBlackUsage"
}

/// Defines the interface of a type that can return a weight value to be used when rendering a font in Rive.
@objc protocol RiveWeightProvider {
    /// The weight to use when rendering a font in Rive.
    var riveWeightValue: Int { get }
}

extension RiveNativeFont: RiveWeightProvider {
    var riveWeightValue: Int {
        let weight: RiveNativeFontWeight?
        
        // First, check if the font has its weight as an available trait within the descriptor.
        // If not, check if the font has its UI usage available as a trait within the descriptor.
        // Otherwise, return a default (400).
        if let traits = fontDescriptor.object(forKey: .traits) as? [RiveNativeFontDescriptor.TraitKey: Any],
           let rawValue = traits[.weight] as? CGFloat {
            weight = RiveNativeFontWeight(rawValue: rawValue)
        } else if let attribute = fontDescriptor.object(forKey: .init(rawValue: "NSCTFontUIUsageAttribute")) as? String,
                  let usage = RiveFallbackFontUIUsage(rawValue: attribute) {
            weight = RiveNativeFontWeight(usage)
        } else {
            weight = nil
        }

        // On iOS, weights are provided as a float in the range of -1.0...1.0.
        // The assumption is that these floats are an addition / subtraction of a value
        // based on the weight of a regular font. Since obtaining the regular font weight
        // is proving difficult, use "sane" defaults, as seen here:
        // https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight#common_weight_name_mapping
        // - David
        switch weight {
        case RiveNativeFontWeight.thin: return 100
        case RiveNativeFontWeight.ultraLight: return 200
        case RiveNativeFontWeight.light: return 300
        case RiveNativeFontWeight.regular: return 400
        case RiveNativeFontWeight.medium: return 500
        case RiveNativeFontWeight.semibold: return 600
        case RiveNativeFontWeight.bold: return 700
        case RiveNativeFontWeight.heavy: return 800
        case RiveNativeFontWeight.black: return 900
        default: return 400
        }
    }
}

/// Defines the interface of a type that can return a width value to be used when rendering a font in Rive.
@objc protocol RiveFontWidthProvider {
    /// The width to use when rendering a font in Rive. This value may be ignored, depending on the font
    /// data loaded by Rive when rendering.
    /// - Note: In some cases, iOS may override any provided weight values when generating fonts.
    var riveFontWidthValue: Int { get }
}

extension RiveNativeFont: RiveFontWidthProvider {
    var riveFontWidthValue: Int {
        // Assume that default widths are 100(%)
        let defaultWidth: CGFloat = 100

        // If there is a width trait available, use that and calculate the updated width.
        // This width value should be in the range -1.0...1.0
        guard let traits = fontDescriptor.object(forKey: .traits) as? [RiveNativeFontDescriptor.TraitKey: Any],
              let width = traits[.width] as? CGFloat
        else {
            return Int(defaultWidth)
        }

        let calculatedWidth = (defaultWidth + (defaultWidth * width)).rounded(.toNearestOrAwayFromZero)
        return Int(calculatedWidth)
    }
}
