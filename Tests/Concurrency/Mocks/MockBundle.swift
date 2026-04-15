//
//  MockBundle.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 5/27/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

class MockBundle: Bundle, @unchecked Sendable {
    private var _urlForResource: ((String?, String?) -> URL?)?
    
    func stubUrlForResource(_ callback: @escaping (String?, String?) -> URL?) {
        _urlForResource = callback
    }
    
    override func url(forResource name: String?, withExtension ext: String?) -> URL? {
        if let stub = _urlForResource {
            return stub(name, ext)
        }
        return super.url(forResource: name, withExtension: ext)
    }
}

