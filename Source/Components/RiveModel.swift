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
    public private(set) var stateMachine: RiveStateMachineInstance?
    public private(set) var animation: RiveLinearAnimationInstance?
    
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
        guard artboard?.name() != name else { return }
        do { artboard = try riveFile.artboard(fromName: name) }
        catch { throw RiveModelError.invalidArtboard(name: name) }
    }
    
    open func setArtboard(_ index: Int? = nil) throws {
        if let index = index {
            do { artboard = try riveFile.artboard(from: index) }
            catch { throw RiveModelError.invalidArtboard(index: index) }
        } else {
            // This tries to find the 'default' Artboard
            do { artboard = try riveFile.artboard() }
            catch { throw RiveModelError.invalidArtboard(message: "No Default Artboard") }
        }
    }
    
    open func setStateMachine(_ name: String) throws {
        guard stateMachine?.name() != name else { return }
        do { stateMachine = try artboard.stateMachine(fromName: name) }
        catch { throw RiveModelError.invalidStateMachine(name: name) }
    }
    
    open func setStateMachine(_ index: Int? = nil) throws {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { stateMachine = try artboard.stateMachine(from: index) }
        catch { throw RiveModelError.invalidStateMachine(index: index) }
    }
    
    open func setAnimation(_ name: String) throws {
        guard animation?.name() != name else { return }
        do { animation = try artboard.animation(fromName: name) }
        catch { throw RiveModelError.invalidAnimation(name: name) }
    }
    
    open func setAnimation(_ index: Int? = nil) throws {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { animation = try artboard.animation(from: index) }
        catch { throw RiveModelError.invalidAnimation(index: index) }
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
        case invalidStateMachine(name: String), invalidStateMachine(index: Int)
        case invalidAnimation(name: String), invalidAnimation(index: Int)
        case invalidArtboard(name: String), invalidArtboard(index: Int), invalidArtboard(message: String)
    }
}
