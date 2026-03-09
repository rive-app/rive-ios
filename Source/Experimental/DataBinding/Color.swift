//
//  Color.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/26/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A struct that represents a color with red, green, blue, and alpha components.
///
/// Colors are used in view model properties and can be created from ARGB integer values
/// or individual component values.
@_spi(RiveExperimental)
public struct Color: Sendable, Equatable {
    public let alpha: UInt8
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    /// Creates a color from a 32-bit ARGB integer value.
    ///
    /// - Parameter color: The ARGB integer value
    public init(_ color: UInt32) {
        self.alpha = UInt8((color & 0xFF000000) >> 24)
        self.red = UInt8((color & 0x00FF0000) >> 16)
        self.green = UInt8((color & 0x0000FF00) >> 8)
        self.blue = UInt8((color & 0x000000FF) >> 0)
    }
    
    /// Creates a color from individual red, green, blue, and alpha components.
    ///
    /// - Parameters:
    ///   - red: The red component (0-255)
    ///   - green: The green component (0-255)
    ///   - blue: The blue component (0-255)
    ///   - alpha: The alpha component (0-255), defaults to 255 (fully opaque)
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public var argbValue: UInt32 {
        return (UInt32(alpha) << 24) |
               (UInt32(red) << 16) |
               (UInt32(green) << 8) |
               (UInt32(blue) << 0)
    }
}
