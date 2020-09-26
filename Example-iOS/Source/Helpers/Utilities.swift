//
//  Utilities.swift
//  RiveExample
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

import Foundation

func loadBytesFromFile(forResource res: String, withExtension ext: String) -> Data?
{
    guard let fileURL = Bundle.main.url(forResource: res, withExtension: ext) else {
        print("Failed to create URL for file.")
        return nil
    }
    do {
        let data = try Data(contentsOf: fileURL)
        return data
    }
    catch {
        print("Error opening file: \(error)")
        return nil
    }
}

extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}
