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
final class MetalDevice: @unchecked Sendable {
    static let shared = MetalDevice()

    private var device: UncheckedSendable<MTLDevice>?
    private var deviceTask: Task<UncheckedSendable<MTLDevice>?, Never>?
    private let lock = NSLock()

    func defaultDevice() -> UncheckedSendable<MTLDevice>? {
        // Serialize access to the cached device.
        lock.withLock {
            if let device { return device }

            // First access pays the system lookup cost once.
            let defaultDevice = MTLCreateSystemDefaultDevice().map(UncheckedSendable.init)

            device = defaultDevice
            return defaultDevice
        }
    }

    func defaultDevice() async -> UncheckedSendable<MTLDevice>? {
        // Fast-path: return cached device without spawning a task.
        if let cached = cachedDevice() {
            return cached
        }
        return await asyncDefaultDevice()
    }

    private func cachedDevice() -> UncheckedSendable<MTLDevice>? {
        // Read the cached device under lock to avoid races.
        lock.withLock { device }
    }

    private func asyncDefaultDevice() async -> UncheckedSendable<MTLDevice>? {
        // Ensure only one async task performs device creation.
        var existingDevice: UncheckedSendable<MTLDevice>?
        var existingTask: Task<UncheckedSendable<MTLDevice>?, Never>?
        var createdTask: Task<UncheckedSendable<MTLDevice>?, Never>?

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

    private func makeDeviceTask() -> Task<UncheckedSendable<MTLDevice>?, Never> {
        return Task.detached { [weak self] in
            self?.defaultDevice()
        }
    }
}
