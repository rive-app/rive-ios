//
//  MockArtboardListener.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

@testable import RiveRuntime

class MockArtboardListener: NSObject, ArtboardListener {
    private(set) var capturedArtboardHandle: UInt64 = 0
    private(set) var capturedRequestID: UInt64 = 0
    private(set) var capturedNames: [String]?
    private(set) var capturedViewModelName: String?
    private(set) var capturedInstanceName: String?
    
    func onStateMachineNamesListed(_ artboardHandle: UInt64, names: [String], requestID: UInt64) {
        capturedArtboardHandle = artboardHandle
        capturedNames = names
        capturedRequestID = requestID
    }

    func onArtboardError(_ artboardHandle: UInt64, requestID: UInt64, message: String) {

    }
    
    func onDefaultViewModelInfoReceived(_ artboardHandle: UInt64, requestID: UInt64, viewModelName: String, instanceName: String) {
        capturedArtboardHandle = artboardHandle
        capturedRequestID = requestID
        capturedViewModelName = viewModelName
        capturedInstanceName = instanceName
    }
}
