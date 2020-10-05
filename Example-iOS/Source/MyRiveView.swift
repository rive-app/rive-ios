//
//  MyViewView.swift
//  RiveExample
//
//  Created by Matt Sullivan on 10/5/20.
//  Copyright © 2020 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class MyRiveView: UIView {

    var artboard: RiveArtboard?;
    
    func updateArtboard(_ artboard: RiveArtboard) {
        self.artboard = artboard;
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: Alignment.Center, with: Fit.Contain)
        artboard.draw(renderer)
    }
}
