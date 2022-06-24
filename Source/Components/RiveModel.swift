//
//  RiveModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

open class RiveModel: ObservableObject {
    private let fileUUID: UInt
    
    internal static var fileCache: RiveFileCache = RiveFileCache()
    internal weak var riveFile: RiveFile! { RiveModel.fileCache.reference(with: fileUUID)!.file }
    
    public private(set) var artboard: RiveArtboard!
    public internal(set) var stateMachine: RiveStateMachineInstance?
    public internal(set) var animation: RiveLinearAnimationInstance?
    
    public init(riveFile: RiveFile) {
        fileUUID = riveFile.uuid
        RiveModel.fileCache.add(riveFile)
    }
    
    public init(fileName: String) throws {
        let file = try RiveFile(name: fileName)
        fileUUID = file.uuid
        RiveModel.fileCache.add(file)
    }
    
    public init(webURL: String, delegate: RiveFileDelegate) {
        let file = RiveFile(httpUrl: webURL, with: delegate)!
        fileUUID = file.uuid
        RiveModel.fileCache.add(file)
    }
    
    deinit {
        RiveModel.fileCache.remove(riveFile)
        //print("RiveView deinit")
    }
    
    // MARK: - Setters
    
    open func setArtboard(_ name: String) throws {
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

internal class RiveFileReference {
    var referenceCount: Int = 0
    var file: RiveFile
    
    init(file: RiveFile) {
        self.file = file
    }
}

internal class RiveFileCache {
    var fileReferences: [RiveFileReference] = []
    
    subscript(index: Int) -> RiveFile { fileReferences[index].file }
    
    func reference(with uuid: UInt) -> RiveFileReference? {
        return fileReferences.first { $0.file.uuid == uuid }
    }
    
    /// Adds this file to the cache if its uuid is unique. If not it increases that cached file's reference count
    func add(_ file: RiveFile) {
        // The RiveFile is already in the cache so we just bump the reference count
        if let cachedRef = (fileReferences.first { $0.file.uuid == file.uuid }) {
            cachedRef.referenceCount += 1
            print("RiveFile UUID: \(cachedRef.file.uuid) referenced -- References: \(cachedRef.referenceCount) -- Files cached: \(fileReferences.count)")
        }
        // The RiveFile is new so we add it to the cache
        else {
            let reference = RiveFileReference(file: file)
            reference.referenceCount = 1
            fileReferences.append(reference)
            print("RiveFile UUID: \(reference.file.uuid) added -- Files cached: \(fileReferences.count)")
        }
    }
    
    /// Decreases the reference count of this file. Removes this file from the cache if its reference count is 0
    func remove(_ file: RiveFile) {
        if let cachedRef = (fileReferences.first { $0.file.uuid == file.uuid }) {
            cachedRef.referenceCount -= 1
            
            // The cached RiveFile has nothing referencing it so it will be removed
            if cachedRef.referenceCount <= 0 {
                fileReferences.removeAll { $0.file.uuid == file.uuid }
                print("RiveFile UUID: \(file.uuid) removed -- Files cached: \(fileReferences.count)")
            }
            // The cached RiveFile has references to it
            else {
                print("RiveFile UUID: \(file.uuid) unreferenced -- References: \(cachedRef.referenceCount) -- Files cached: \(fileReferences.count)")
            }
        }
    }
}
