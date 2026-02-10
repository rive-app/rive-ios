//
//  MetalDevice.swift
//  RiveRuntime
//
//  Created by David Skuza on 1/27/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import Foundation
import Metal

/// Singleton that safely caches the system default Metal device.
final class MetalDevice {
    static let shared = MetalDevice()

    private var device: MTLDevice?
    private var deviceTask: Task<MTLDevice?, Never>?
    private let lock = NSLock()

    func defaultDevice() -> MTLDevice? {
        // Serialize access to the cached device.
        lock.withLock {
            if let device { return device }

            // First access pays the system lookup cost once.
            let defaultDevice = MTLCreateSystemDefaultDevice()

            device = defaultDevice
            return defaultDevice
        }
    }

    func defaultDevice() async -> MTLDevice? {
        // Fast-path: return cached device without spawning a task.
        if let cached = cachedDevice() {
            return cached
        }
        return await asyncDefaultDevice()
    }

    private func cachedDevice() -> MTLDevice? {
        // Read the cached device under lock to avoid races.
        lock.withLock { device }
    }

    private func asyncDefaultDevice() async -> MTLDevice? {
        // Ensure only one async task performs device creation.
        var existingDevice: MTLDevice?
        var existingTask: Task<MTLDevice?, Never>?
        var createdTask: Task<MTLDevice?, Never>?

        lock.withLock {
            if let cachedDevice = self.device {
                existingDevice = cachedDevice
                return
            }
            if let deviceTask {
                existingTask = deviceTask
                return
            }
            let task = makeDeviceTask()
            deviceTask = task
            createdTask = task
        }

        if let existingDevice {
            return existingDevice
        }

        let task = existingTask ?? createdTask
        let resolvedDevice = await task?.value

        if createdTask != nil {
            // Clear in-flight state after completion.
            lock.withLock {
                deviceTask = nil
            }
        }

        return resolvedDevice
    }

    private func makeDeviceTask() -> Task<MTLDevice?, Never> {
        if Thread.isMainThread {
            // Ensure we don't block the main thread while creating the device.
            return Task.detached(priority: .userInitiated) { [weak self] in
                self?.defaultDevice()
            }
        }
        return Task(priority: .userInitiated) { [weak self] in
            self?.defaultDevice()
        }
    }
}
