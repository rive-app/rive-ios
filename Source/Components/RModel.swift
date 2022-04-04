//
//  RModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

public struct RModel { // TODO: Rename to RAssetState
    public let url: String? = nil
    public let assetName: String? // TODO: Rename to fileName
    public var fit: RiveRuntime.Fit = .fitContain
    public var alignment: RiveRuntime.Alignment = .alignmentCenter
    public var autoplay: Bool = true
    public var artboard: String? = nil
    public var animation: String? = nil
    public var stateMachine: String? = nil
    public var touchedLocation: CGPoint? = nil
}
