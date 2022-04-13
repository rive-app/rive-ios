//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI

//class SimpleAnimationViewController: UIViewController {
//    let resourceName = "truck_v7"
//
//    override public func loadView() {
//        super.loadView()
//
//        let view = RiveView()
//        view.fit = Fit.fitCover
//        do{
//            let riveFile = try RiveFile(resource: resourceName)
//            try view.configure(riveFile)
//        } catch {
//          print(error)
//        }
//
//        self.view = view
//    }
//
//    override public func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//    }
//}


class SimpleAnimationViewController: UIViewController {
    let url = "https://cdn.rive.app/animations/truck.riv"

    override public func loadView() {
        super.loadView()

        let view = RiveView()
        guard let riveFile = RiveFile(httpUrl: url, with: view) else {
            fatalError("Unable to load RiveFile")
        }
        try? view.configure(riveFile)

        self.view = view
    }
}
