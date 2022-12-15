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
    public internal(set) var stateMachine: RiveStateMachineInstance?
    public internal(set) var animation: RiveLinearAnimationInstance?
    
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
    
    /// Sets a new Artboard and makes the current StateMachine and Animation nil
    open func setArtboard(_ name: String) throws {
        do {
            stateMachine = nil
            animation = nil
            artboard = try riveFile.artboard(fromName: name)
        }
        catch { throw RiveModelError.invalidArtboard("Name \(name) not found") }
    }
    
    /// Sets a new Artboard and makes the current StateMachine and Animation nil
    open func setArtboard(_ index: Int? = nil) throws {
        if let index = index {
            do {
                stateMachine = nil
                animation = nil
                artboard = try riveFile.artboard(from: index)
            }
            catch { throw RiveModelError.invalidArtboard("Index \(index) not found") }
        } else {
            // This tries to find the 'default' Artboard
            do { artboard = try riveFile.artboard() }
            catch { throw RiveModelError.invalidArtboard("No Default Artboard") }
        }
    }
    
    open func setStateMachine(_ name: String) throws {
        do { stateMachine = try artboard.stateMachine(fromName: name) }
        catch { throw RiveModelError.invalidStateMachine("Name \(name) not found") }
    }
    
    open func setStateMachine(_ index: Int? = nil) throws {
        do {
            // Set by index
            if let index = index {
                stateMachine = try artboard.stateMachine(from: index)
            }
            
            // Set from Artboard's default StateMachine configured in editor
            else if let defaultStateMachine = artboard.defaultStateMachine() {
                stateMachine = defaultStateMachine
            }
            
            // Set by index 0 as a fallback
            else {
                stateMachine = try artboard.stateMachine(from: 0)
            }
        }
        catch { throw RiveModelError.invalidStateMachine("Index \(index ?? 0) not found") }
    }
    
    open func setAnimation(_ name: String) throws {
        guard animation?.name() != name else { return }
        do { animation = try artboard.animation(fromName: name) }
        catch { throw RiveModelError.invalidAnimation("Name \(name) not found") }
    }
    
    open func setAnimation(_ index: Int? = nil) throws {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { animation = try artboard.animation(from: index) }
        catch { throw RiveModelError.invalidAnimation("Index \(index) not found") }
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
    
    enum RiveModelError: Error {
        case invalidStateMachine(_ message: String)
        case invalidAnimation(_ message: String)
        case invalidArtboard(_ message: String)
    }
}
