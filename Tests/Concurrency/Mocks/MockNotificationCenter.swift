//
//  MockNotificationCenter.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/5/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import Foundation
@testable import RiveRuntime

class MockNotificationCenter: NotificationCenterProtocol {
    private var observers: [(token: NSObject, name: NSNotification.Name?, block: @Sendable (Notification) -> Void)] = []

    func addObserver(
        forName name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping @Sendable (Notification) -> Void
    ) -> any NSObjectProtocol {
        let token = NSObject()
        observers.append((token: token, name: name, block: block))
        return token
    }

    func removeObserver(_ observer: Any) {
        guard let token = observer as? NSObject else { return }
        observers.removeAll { $0.token === token }
    }

    func fire(name: NSNotification.Name) {
        for observer in observers where observer.name == name {
            observer.block(Notification(name: name))
        }
    }
}

#endif
