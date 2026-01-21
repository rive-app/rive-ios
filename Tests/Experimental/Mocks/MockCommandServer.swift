//
//  MockCommandServer.swift
//  RiveRuntime
//
//  Created by David Skuza on 6/5/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import RiveRuntime

class MockCommandServer: CommandServerProtocol {
    private var serveStub: (() -> Void)?
    private(set) var serveUntilDisconnectCalls: [ServeUntilDisconnectCall] = []

    func stubServeUntilDisconnect(_ stub: @escaping () -> Void) {
        serveStub = stub
    }

    func serveUntilDisconnect() {
        serveUntilDisconnectCalls.append(ServeUntilDisconnectCall())
        serveStub?()
    }
}

extension MockCommandServer {
    struct ServeUntilDisconnectCall {
    }
}
