//
//  MockFileListener.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 6/3/25.
//  Copyright © 2025 Rive. All rights reserved.
//

@testable import RiveRuntime

class MockFileListener: NSObject, FileListener {
    private(set) var capturedFileHandle: UInt64 = 0
    private(set) var capturedRequestID: UInt64 = 0
    private(set) var capturedMessage: String = ""
    private(set) var capturedArtboardNames: [String]?
    private(set) var capturedViewModelNames: [String]?
    private(set) var capturedViewModelInstanceNames: [String]?
    private(set) var capturedViewModelName: String?
    private(set) var capturedViewModelEnums: [[String: Any]]?
    private(set) var capturedViewModelProperties: [[String: Any]]?

    func onFileLoaded(_ handle: UInt64, requestID: UInt64) {
        capturedFileHandle = handle
        capturedRequestID = requestID
    }
    
    func onFileDeleted(_ handle: UInt64, requestID: UInt64) {
        capturedFileHandle = handle
        capturedRequestID = requestID
    }
    
    func onFileError(_ fileHandle: UInt64, requestID: UInt64, message: String) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedMessage = message
    }
    
    func onArtboardsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedArtboardNames = names
    }

    func onViewModelsListed(_ fileHandle: UInt64, requestID: UInt64, names: [String]) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedViewModelNames = names
    }

    func onViewModelInstanceNamesListed(_ fileHandle: UInt64, requestID: UInt64, viewModelName: String, names: [String]) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedViewModelName = viewModelName
        capturedViewModelInstanceNames = names
    }

    func onViewModelEnumsListed(_ fileHandle: UInt64, requestID: UInt64, enums: [[String: Any]]) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedViewModelEnums = enums
    }

    func onViewModelPropertiesListed(_ fileHandle: UInt64, requestID: UInt64, viewModelName: String, properties: [[String: Any]]) {
        capturedFileHandle = fileHandle
        capturedRequestID = requestID
        capturedViewModelName = viewModelName
        capturedViewModelProperties = properties
    }
}
