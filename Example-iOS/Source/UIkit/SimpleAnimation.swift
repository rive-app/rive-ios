//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime


class SimpleAnimationViewController: RiveViewController {
    let resourceName = "truck_v7"
    let resourceExt = ".riv"
    
    
    override func setRiveFile() -> RiveFile {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) else {
            fatalError("Failed to locate \(resourceName) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        return data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer)->RiveFile in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            return riveFile
        }
    }
}
