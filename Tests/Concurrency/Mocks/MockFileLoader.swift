//
//  MockFileLoader.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/27/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

final class MockFileLoader: FileLoaderProtocol, @unchecked Sendable {
    private var _load: (() async throws -> Data)?

    func stubLoad(_ load: @escaping () async throws -> Data) {
        _load = load
    }

    func load() async throws -> Data {
        return try await _load?() ?? Data()
    }
}
