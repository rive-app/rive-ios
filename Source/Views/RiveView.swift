//
//  RiveView.swift
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/30/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit

public class RiveView: UIView {

    var artboard: RiveArtboard?
    var fit = Fit.Contain
    var alignment = Alignment.Center
    
    /*
     * Updates the artboard and layout options
     */
    func updateArtboard(
        withArtboard artboard: RiveArtboard,
        withFit fit: Fit?,
        withAlignment alignment: Alignment?
    ) {
        self.artboard = artboard
        // TODO: is there a more Swift-y way to do these?
        self.fit = fit ?? self.fit
        self.alignment = alignment ?? self.alignment
    }
    
    /*
     * Creates a Rive renderer and applies the currently animating artboard to it
     */
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: alignment, with: fit)
        artboard.draw(renderer)
    }
}
