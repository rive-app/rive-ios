//
//  ScaleFactorProvider.swift
//  RiveRuntime
//
//  Created by David Skuza on 12/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// A protocol that provides scale information for layout-based fitting.
///
/// Used by `Fit.layout` to determine the appropriate scale factor. The `nativeScale` is
/// preferred when available (e.g., from a window's screen), otherwise `displayScale` is used.
/// Implemented by `RiveUIView` to provide scale information from the view's window and trait collection.
@MainActor
protocol ScaleProvider {
    var nativeScale: CGFloat? { get }
    var displayScale: CGFloat { get }
}
