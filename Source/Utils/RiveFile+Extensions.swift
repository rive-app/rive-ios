//
//  RiveFile+Extensions.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 4/7/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

public extension RiveFile {
    convenience init(name fileName: String, extension ext: String = ".riv", in bundle: Bundle = .main, loadCdn: Bool=true, customLoader: LoadAsset? = nil) throws {
        RiveLogger.log(loadingFromResource: "\(fileName)\(ext)")
        let byteArray = RiveFile.getBytes(fileName: fileName, extension: ext, in: bundle)
        if (customLoader == nil){
            try self.init(byteArray: byteArray, loadCdn: loadCdn)
        }else {
            try self.init(byteArray: byteArray, loadCdn: loadCdn, customAssetLoader: customLoader!)
        }
    }
    
    static func getBytes(fileName: String, extension ext: String = ".riv", in bundle: Bundle = .main) -> [UInt8] {
        guard let url = bundle.url(forResource: fileName, withExtension: ext) else {
            let errorMessage = "Failed to locate \(fileName) in bundle \(bundle)."
            RiveLogger.log(file: nil, event: .fatalError(errorMessage))
            fatalError(errorMessage)
        }
        guard let data = try? Data(contentsOf: url) else {
            let errorMessage = "Failed to load \(url) from bundle."
            RiveLogger.log(file: nil, event: .fatalError(errorMessage))
            fatalError()
        }
        
        // Import the data into a RiveFile
        return [UInt8](data)
    }
}
