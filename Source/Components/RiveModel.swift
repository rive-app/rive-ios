//
//  RiveModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

open class RiveModel: ObservableObject {
    internal private(set) var riveFile: RiveFile
    public private(set) var artboard: RiveArtboard!
    public internal(set) var scene: RiveScene!
    public internal(set) var stateMachine: RiveStateMachineInstance? {
        didSet {
            scene = stateMachine ?? scene
        }
    }
    public internal(set) var animation: RiveLinearAnimationInstance? {
        didSet {
            scene = animation ?? scene
        }
    }
    
    public init(riveFile: RiveFile) {
        self.riveFile = riveFile
    }
    
    public init(fileName: String) throws {
        riveFile = try RiveFile(name: fileName)
    }
    
    public init(webURL: String, delegate: RiveFileDelegate) {
        riveFile = RiveFile(httpUrl: webURL, with: delegate)!
    }
    
    // MARK: - Setters
    
    open func setArtboard(_ name: String) throws {
        artboard = try riveFile.artboard(fromName: name)
    }
    
    open func setArtboard(_ index: Int? = nil) throws {
        if let index = index {
            artboard = try riveFile.artboard(from: index)
        }
        else {
            // Tries to find the 'default' Artboard
            artboard = try riveFile.defaultArtboard()
        }
    }
    
    open func setStateMachine(_ name: String) throws {
        stateMachine = try artboard.stateMachine(fromName: name)
    }
    
    open func setStateMachine(_ index: Int? = nil) throws {
        if let index = index {
            stateMachine = try artboard.stateMachine(from: index)
        } else {
            // Tries to find the 'default' StateMachine
            stateMachine = try artboard.defaultStateMachine()
        }
    }
    
    open func setDefaultScene() throws {
        let newScene = try artboard.defaultScene()
        if newScene is RiveStateMachineInstance {
            stateMachine = newScene as? RiveStateMachineInstance
        } else {
            animation = newScene as? RiveLinearAnimationInstance
        }
    }
    
    open func setAnimation(_ name: String) throws {
        animation = try artboard.animation(fromName: name)
    }
    
    open func setAnimation(_ index: Int? = nil) throws {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        animation = try artboard.animation(from: index)
    }
    
    // MARK: -
    
    public var description: String {
        let art = "RiveModel - [Artboard: " + artboard.name()
        
        if let stateMachine = stateMachine {
            return art + "StateMachine: " + stateMachine.name() + "]"
        }
        else if let animation = animation {
            return art + "Animation: " + animation.name() + "]"
        }
        else {
            return art + "]"
        }
    }
}
