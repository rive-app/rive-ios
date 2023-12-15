//
//  File.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI


func loadAndSetRenderImage(named resourceName: String, asset: RiveImageAsset, factory: RiveFactory) -> Bool {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "jpeg"),
          let data = try? Data(contentsOf: url)
    else {
        fatalError("Failed to load or locate '\(resourceName)' in bundle.")
    }
    asset.renderImage(factory.decodeImage(data))
    return true
}

func loadAndSetRenderFont(named resourceName: String, asset: RiveFontAsset, factory: RiveFactory) -> Bool {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "ttf"),
          let data = try? Data(contentsOf: url)
    else {
        fatalError("Failed to load or locate '\(resourceName)' in bundle.")
    }
    asset.font(factory.decodeFont(data))
    return true
}

class SimpleOutOfBandController: UIViewController, UIGestureRecognizerDelegate {
    var loader: AssetLoader = AssetLoader();
    var viewModel: RiveViewModel?;
    
    required init?(coder: NSCoder) {
        
        self.viewModel = RiveViewModel(fileName: "simple_assets", loadCdn: false, customLoader: { (asset: RiveFileAsset, data: Data, factory: RiveFactory) -> Bool in
            if let imageAsset = asset as? RiveImageAsset {
                return loadAndSetRenderImage(named: "picture-47982", asset: imageAsset, factory: factory)
            } else if let fontAsset = asset as? RiveFontAsset {
                return loadAndSetRenderFont(named: "Inter-45562", asset: fontAsset, factory: factory)
            }
            
            return false;
        }
        )
        super.init(coder: coder);
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let riveView = viewModel!.createRiveView()
        view.addSubview(riveView)
        riveView.frame = view.frame
    }
}
