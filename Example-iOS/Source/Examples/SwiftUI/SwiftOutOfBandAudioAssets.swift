//
//  SwiftAudioAssets.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 11/04/2024.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation


import SwiftUI
import RiveRuntime

struct SwiftOutOfBandAudioAssets: DismissableView {
    var dismiss: () -> Void = {}
    @StateObject private var riveViewModel = RiveViewModel(
        fileName: "ping_pong_audio_demo",
        stateMachineName: "State Machine 1",
        autoPlay: true, 
        loadCdn: false,
        customLoader: { (asset: RiveFileAsset, data: Data, factory: RiveFactory) -> Bool in
            
            if (asset is RiveAudioAsset){
                guard let url = (.main as Bundle).url(forResource: asset.uniqueName(), withExtension: asset.fileExtension()) else {
                    fatalError("Failed to load asset \(asset.uniqueFilename()) from bundle.")
                }
                guard let data = try? Data(contentsOf: url) else {
                    fatalError("Failed to load \(url) from bundle.")
                }
                
                (asset as! RiveAudioAsset).audio(
                    factory.decodeAudio(data)
                )
                return true;

            }
//            
            return true;
        }
    );
    
    var body: some View {
        
        riveViewModel.view()
    }
}
