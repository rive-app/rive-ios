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
    public let fileName: String?
    public var fit: RiveRuntime.Fit = .fitContain
    public var alignment: RiveRuntime.Alignment = .alignmentCenter
    public var autoplay: Bool = true
    public var artboard: String? = nil
    public var animation: String? = nil
    public var stateMachineName: String? = nil
    
    public var description: String {
          "URL: "           + (url ?? "None")           + "/n"
        + "File Name: "     + (fileName ?? "None")      + "/n"
        + "Fit: "           + fit.description           + "/n"
        + "Alignment: "     + alignment.description     + "/n"
        + "Autoplay: "      + autoplay.description      + "/n"
        + "Artboard: "      + (artboard ?? "None")      + "/n"
        + "Animation: "     + (animation ?? "None")     + "/n"
        + "State Machine: " + (stateMachineName ?? "None")  + "/n"
    }
    
    public init(fileName: String?, stateMachineName: String? = nil) {
        self.fileName = fileName
        self.stateMachineName = stateMachineName
    }
}

public extension RiveRuntime.Fit {
    var description: String {
        switch self {
        case .fitNone:      return "None"
        case .fitFill:      return "Fill"
        case .fitContain:   return "Contain"
        case .fitCover:     return "Cover"
        case .fitFitHeight: return "Fit Height"
        case .fitFitWidth:  return "Fit Width"
        case .fitScaleDown: return "Scale Down"
        @unknown default:   return "Unknown"
        }
    }
}

public extension RiveRuntime.Alignment {
    var description: String {
        switch self {
        case .alignmentCenter:          return "Center"
        case .alignmentCenterLeft:      return "Center Left"
        case .alignmentCenterRight:     return "Center Right"
        case .alignmentTopLeft:         return "Top Left"
        case .alignmentTopCenter:       return "Top Center"
        case .alignmentTopRight:        return "Top Right"
        case .alignmentBottomLeft:      return "Bottom Left"
        case .alignmentBottomCenter:    return "Bottom Center"
        case .alignmentBottomRight:     return "Bottom Right"
        @unknown default:               return "Unknown"
        }
    }
}
