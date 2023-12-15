//
//  SwiftSimpleAssets.swift
//  Example (iOS)
//
//  Created by Maxwell Talbot on 20/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct SwiftSimpleAssets: DismissableView {
    var dismiss: () -> Void = {}
    @StateObject private var riveViewModel = RiveViewModel(fileName: "simple_assets", autoPlay: false, loadCdn: false, customLoader: { (asset: RiveFileAsset, data: Data, factory: RiveFactory) -> Bool in
        
        if (asset is RiveImageAsset){
            
            guard let url = (.main as Bundle).url(forResource: "picture-47982", withExtension: "jpeg") else {
                fatalError("Failed to locate 'picture-47982' in bundle.")
            }
            guard let data = try? Data(contentsOf: url) else {
                fatalError("Failed to load \(url) from bundle.")
            }
            (asset as! RiveImageAsset).renderImage(
                factory.decodeImage(data)
            )
            return true;
        }else if (asset is RiveFontAsset) {
            guard let url = (.main as Bundle).url(forResource: "Inter-45562", withExtension: "ttf") else {
                fatalError("Failed to locate 'Inter-45562' in bundle.")
            }
            guard let data = try? Data(contentsOf: url) else {
                fatalError("Failed to load \(url) from bundle.")
            }
            
            (asset as! RiveFontAsset).font(
                factory.decodeFont(data)
            )
            return true;
        }
        
        return false;
    });
    
    var body: some View {
        riveViewModel.view()
    }
}
