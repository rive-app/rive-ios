//
//  NotificationListener.swift
//  RiveRuntime
//
//  Created by David Skuza on 3/19/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import Foundation

enum Notifications {
    private static let lock = NSLock()
    private static var observers: [NSObjectProtocol] = []
    private static var observerCount = 0

    static func observe() {
        let shouldRegister = lock.withLock {
            observerCount += 1
            return observerCount == 1
        }

        guard shouldRegister else { return }

        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            AudioEngine.start()
        }

        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            AudioEngine.stop()
        }

        lock.withLock {
            observers.append(activeObserver)
            observers.append(backgroundObserver)
        }
    }

    static func unobserve() {
        let (shouldUnregister, tokens): (Bool, [NSObjectProtocol]) = lock.withLock {
            guard observerCount > 0 else {
                return (false, [])
            }
            observerCount -= 1
            let shouldUnregister = observerCount == 0
            let tokens = shouldUnregister ? observers : []
            if shouldUnregister {
                observers.removeAll()
            }
            return (shouldUnregister, tokens)
        }

        guard shouldUnregister else { return }
        for observer in tokens {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
#endif
