//
//  StressTest.swift
//  RiveExample
//
//  Created by Chris Dalton on 1/30/23.
//  Copyright © 2023 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI

// Example to test drawing multiple times within a single view
class StressTestViewController: UIViewController {
    var viewModel: RiveViewModel?
    var rView: CustomRiveView?

    @objc func onTap(_ sender:UITapGestureRecognizer) {
        if let riveView = rView {
            riveView.drawRepeat += 3;
            self.title = "Stress Test (x\(riveView.drawRepeat))"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        let rModel = try! RiveModel(fileName: "marty", extension: ".riv", in: .main)
        rView = CustomRiveView(model: rModel, autoPlay: true)
        viewModel = RiveViewModel(rModel, animationName: "Animation2")
        viewModel!.fit = RiveFit.contain
        viewModel!.setView(rView!)
        view.addSubview(rView!)
        let f = view.frame
        #if os(visionOS)
        let h: CGFloat = 0
        #else
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let h = statusBarHeight + 40
        #endif
        rView!.frame = CGRect(x:f.minX, y:f.minY + h, width:f.width, height:f.height - h)

        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.onTap (_:)))
        rView!.addGestureRecognizer(gesture)

        rView!.showFPS = true
    }
}

// New RiveView that overrides the drawing logic to re-draw the view multiple times.
class CustomRiveView: RiveView {
    private var rModel: RiveModel?
    public var drawRepeat: Int32 = 1
    init(model: RiveModel, autoPlay: Bool = true) {
        super.init()
        rModel = model
    }

    #if os(visionOS)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    #else
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    #endif

    override func drawRive(_ rect: CGRect, size: CGSize) {
        // This prevents breaking when loading RiveFile async
        guard let artboard = rModel?.artboard else { return }
        
        let newFrame = CGRect(origin: rect.origin, size: size)
        align(with: newFrame, contentRect: artboard.bounds(), alignment: .center, fit: .contain, scaleFactor: 1.0)
        
        let pad:Float = 100.0
        let r = min(drawRepeat, 8)
        let x0:Float = Float(r - 1) * 0.5 * -pad
        var x:Float = x0
        var y:Float = -pad * 4
        for i in 1...drawRepeat {
            if (i & 0x7) == 0 {
                y += pad
                x = x0
            }
            save()
            transform(1, xy:0, yx:0, yy:1, tx:x, ty:y);
            draw(with: artboard)
            restore()
            x += pad
        }
    }
}
