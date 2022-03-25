//
//  RModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI

open class RModel {
    public let url: String? = nil
    public let assetName: String?
    @Binding public var fit: RiveRuntime.Fit
    @Binding public var alignment: RiveRuntime.Alignment
    public var autoplay: Bool
    public var artboard: String?
    public var animation: String?
    public var stateMachine: String?
    public var touchedLocation: CGPoint?
    
    public init(
        asset: String,
        fit: Binding<RiveRuntime.Fit> = .constant(.fitFill),
        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
        autoplay: Bool = true,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        touchedLocation: CGPoint? = nil
    ) {
        self.assetName = asset
        _fit = fit
        _alignment = alignment
        self.autoplay = autoplay
        self.artboard = artboard
        self.animation = animation
        self.stateMachine = stateMachine
        self.touchedLocation = touchedLocation
    }
    
    // TODO: 
}
