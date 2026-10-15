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

// Observer storage is protected by the lock; callbacks execute after unlocking.
final class MockNotificationCenter: NotificationCenterProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var observers: [(token: NSObject, name: NSNotification.Name?, block: @Sendable (Notification) -> Void)] = []

    func addObserver(
        forName name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping @Sendable (Notification) -> Void
    ) -> any NSObjectProtocol {
        let token = NSObject()
        lock.withLock {
            observers.append((token: token, name: name, block: block))
        }
        return token
    }

    func removeObserver(_ observer: Any) {
        guard let token = observer as? NSObject else { return }
        lock.withLock {
            observers.removeAll { $0.token === token }
        }
    }

    func fire(name: NSNotification.Name) {
        let callbacks = lock.withLock {
            observers.filter { $0.name == name }.map { $0.block }
        }
        for callback in callbacks {
            callback(Notification(name: name))
        }
    }
}

#endif
