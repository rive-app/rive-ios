//
//  utility.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 06/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

@available(*, deprecated, message: "Use method in RiveFile+Extensions instead")
func getBytes(resourceName: String, resourceExt: String=".riv") -> [UInt8] {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) else {
        fatalError("Failed to locate \(resourceName) in bundle.")
    }
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    return [UInt8](data)
}

@available(*, deprecated, message: "Use convenience init in RiveFile+Extensions instead")
func getRiveFile(resourceName: String, resourceExt: String=".riv") throws -> RiveFile{
    let byteArray = getBytes(resourceName: resourceName, resourceExt: resourceExt)
    return try RiveFile(byteArray: byteArray)
}

struct SwiftVMPlayer: View {
    let viewModels: [RiveViewModel]
    
    init(viewModels: RiveViewModel...) {
        self.viewModels = viewModels
    }
    
    var body: some View {
        ZStack {
            Color.gray
                
            VStack {
                ForEach(0 ..< viewModels.count) { i in
                    viewModels[i].view()
                }
                
                HStack {
                    PlayerButton(title: "play") {
                        viewModels.forEach { $0.play() }
                    }
                    
                    PlayerButton(title: "pause") {
                        viewModels.forEach { $0.pause() }
                    }
                    
                    PlayerButton(title: "stop") {
                        viewModels.forEach { $0.stop() }
                    }
                    
                    PlayerButton(title: "backward.end") {
                        viewModels.forEach { $0.reset() }
                    }
                }
            }
            .padding()
        }
        .ignoresSafeArea()
    }
    
    struct PlayerButton: View {
        var title: String
        var action: ()->Void
        
        var body: some View {
            Button {
                action()
            } label: {
                ZStack {
                    Color.blue
                    Image(systemName: title + ".fill")
                        .foregroundColor(.white)
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .padding()
            }
        }
    }
}
