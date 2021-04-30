//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

public class RiveView: UIView {

    var artboard: RiveArtboard?;
    
    func updateArtboard(_ artboard: RiveArtboard) {
        self.artboard = artboard;
    }
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: Alignment.Center, with: Fit.Contain)
        artboard.draw(renderer)
    }
}
