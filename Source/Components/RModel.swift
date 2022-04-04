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





//struct RConfig {
//    let riveFile: RiveFile
//    var artboard: String? = nil
//    var animation: String? = nil
//    var stateMachine: String?
//    var autoPlay: Bool = true
//}

//open class RModel {
//    public let url: String? = nil
//    public let assetName: String?
//    @Binding public var fit: RiveRuntime.Fit
//    @Binding public var alignment: RiveRuntime.Alignment
//    public var autoplay: Bool
//    public var artboard: String?
//    public var animation: String?
//    public var stateMachine: String?
//    public var touchedLocation: CGPoint?
//
//    public init(
//        asset: String,
//        fit: Binding<RiveRuntime.Fit> = .constant(.fitFill),
//        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
//        autoplay: Bool = true,
//        artboard: String? = nil,
//        animation: String? = nil,
//        stateMachine: String? = nil,
//        touchedLocation: CGPoint? = nil
//    ) {
//        self.assetName = asset
//        _fit = fit
//        _alignment = alignment
//        self.autoplay = autoplay
//        self.artboard = artboard
//        self.animation = animation
//        self.stateMachine = stateMachine
//        self.touchedLocation = touchedLocation
//    }
//}
