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
        let data = RiveFile.getData(fileName: fileName, extension: ext, in: bundle)
        if let customLoader = customLoader {
            try self.init(data: data, loadCdn: loadCdn, customAssetLoader: customLoader)
        } else {
            try self.init(data: data, loadCdn: loadCdn)
        }
    }
    
    static func getBytes(fileName: String, extension ext: String = ".riv", in bundle: Bundle = .main) -> [UInt8] {
        let data = getData(fileName: fileName, extension: ext, in: bundle)

        // Import the data into a RiveFile
        return [UInt8](data)
    }

    static func getData(fileName: String, extension ext: String = ".riv", in bundle: Bundle = .main) -> Data {
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

        return data
    }
}
