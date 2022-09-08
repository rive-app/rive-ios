//
//  RiveFile+Extensions.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 4/7/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

public extension RiveFile {
    convenience init(name fileName: String, extension ext: String = ".riv", bundle: Bundle = .main) throws {
        let byteArray = RiveFile.getBytes(fileName: fileName, extension: ext, bundle: bundle)
        try self.init(byteArray: byteArray)
    }
    
    static func getBytes(fileName: String, extension ext: String = ".riv", bundle: Bundle = .main) -> [UInt8] {
        guard let url = bundle.url(forResource: fileName, withExtension: ext) else {
            fatalError("Failed to locate \(fileName) in bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        return [UInt8](data)
    }
}
