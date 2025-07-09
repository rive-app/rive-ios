//
//  RiveSystemFontProvider.swift
//  RiveRuntime
//
//  Created by David Skuza on 8/14/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation

/// A type that is capable of providing fonts usable as fallback fonts.
@objc public protocol RiveFallbackFontProvider {
    /// An array of possible fonts to use as fallback fonts.
    @objc var fallbackFont: RiveNativeFont { get }
}
