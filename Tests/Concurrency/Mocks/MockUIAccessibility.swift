//
//  MockUIAccessibility.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/5/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit
@testable import RiveRuntime

class MockUIAccessibility: UIAccessibilityProtocol {
    nonisolated(unsafe) static var isVoiceOverRunning: Bool = false
    nonisolated(unsafe) static var postedNotifications: [(notification: UIAccessibility.Notification, argument: Any?)] = []

    static func post(notification: UIAccessibility.Notification, argument: Any?) {
        postedNotifications.append((notification: notification, argument: argument))
    }

    static func reset() {
        isVoiceOverRunning = false
        postedNotifications = []
    }
}

#endif
