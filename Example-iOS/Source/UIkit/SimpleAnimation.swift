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
    
    override func setRiveFile() -> RiveFile {
        return getRiveFile(resourceName: resourceName)
    }
}
