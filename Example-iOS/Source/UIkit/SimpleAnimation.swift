//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

func getResourceBytes(resourceName: String, resourceExt: String=".riv") -> [UInt8] {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) else {
        fatalError("Failed to locate \(resourceName) in bundle.")
    }
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    return [UInt8](data)
}


class SimpleAnimationViewController: UIViewController {
    let resourceName = "truck_v7"
    
    override public func loadView() {
        super.loadView()
        
        let view = RiveView()
        guard let riveFile = RiveFile(byteArray: getResourceBytes(resourceName: resourceName)) else {
            fatalError("Failed to load RiveFile")
        }
        view.configure(riveFile)
        
        self.view = view
    }
}
