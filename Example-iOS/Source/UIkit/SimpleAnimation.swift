//
//  SimpleAnimation.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class SimpleAnimationViewController: UIViewController {
    let resourceName = "truck_v7"
    
    override public func loadView() {
        super.loadView()
        
        let view = RiveView()
        view.fit = Fit.fitCover
        guard let riveFile = RiveFile(resource: resourceName) else {
            fatalError("Failed to load RiveFile")
        }

        view.configure(riveFile)
        self.view = view
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        (view as! RiveView).stop()
    }
}

/*
class SimpleAnimationViewController: UIViewController {
     let url = "https://cdn.rive.app/animations/truck.riv"
     
     override public func loadView() {
         super.loadView()
         
         let view = RiveView()
         guard let riveFile = RiveFile(httpUrl: url, with: view) else {
             fatalError("Unable to load RiveFile")
         }
         
         view.configure(riveFile)
         self.view = view
     }
 }
 */
