//
//  SingleDrawRiveView.swift
//  golden_test_app
//
//  Created by Jonathon Copeland on 5/17/24.
//

import UIKit
import SwiftUI
import RiveRuntime
import Foundation
import UniformTypeIdentifiers
import MobileCoreServices

struct GoldenTestViewRepresentable : UIViewRepresentable {

    public init() {
    }
    
    func makeUIView(context: Context) -> SingleDrawRiveView {
        return SingleDrawRiveView()
    }
    
    func updateUIView(_ uiView: SingleDrawRiveView, context: Context) {
       
    }
    
    public static func dismantleUIView(_ view: SingleDrawRiveView, coordinator: Coordinator) {
    }
    
    /// Constructs a coordinator for managing updating state
    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    public class Coordinator: NSObject {

    }
}

open class SingleDrawRiveView: RiveView {
    
    var currentModelIndex = -1
    let modelsToRun = ["vector","dwarf", "text"]
    var viewModel: RiveViewModel?
    var canRender = 1
    var texture: MTLTexture?;
    
    public override init() {
        super.init()
        self.framebufferOnly = false
        self.autoResizeDrawable = false
        self.drawableSize = CGSizeMake(860, 540)
        self.deleteLocalCache()
        self.updateToNextRiveModel()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func draw(in rect: CGRect, withCompletion completionHandler: MTLCommandBufferHandler? = nil) {
        super.draw(in: rect){ commandBuffer in
            DispatchQueue.main.async {
                commandBuffer .waitUntilCompleted()
                guard let texture = self.texture else {
                    return
                }
                
                self.saveTexturePNG(texture: texture)
            }
        }
    }
    
    open override func draw(_ rect: CGRect) {
        
        guard canRender > 0 else{
            return;
        }
        
        texture = self.currentDrawable?.texture
        
        super.draw(rect)
        
        canRender -= 1;
    }
    
    func saveTexturePNG(texture:MTLTexture){
        let options = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                       CIContextOption.outputColorSpace: true,
                       CIContextOption.useSoftwareRenderer: false] as! [CIImageOption : Any]
        guard let ciimage = CIImage(mtlTexture: texture, options: options) else {
            print("CIImage not created")
            return
        }
        let flipped = ciimage.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
        guard let cgImage = CIContext().createCGImage(flipped,
                                                      from: flipped.extent,
                                                      format: CIFormat.RGBA8,
                                                      colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)  else {
            print("CGImage not created")
            return
        }

        guard let baseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let urlString = baseUrl.absoluteString + modelsToRun[currentModelIndex] + ".png"
        guard let url = URL(string: urlString) else {
            return
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG as CFString, 1, nil) else {
            return
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        
        if (CGImageDestinationFinalize(destination) == false){
            print("Failed to save \(url.absoluteString)" )
        }
        
        self.updateToNextRiveModel()
    }
    
    func deleteLocalCache(){
        
        guard let baseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        for filename in self.modelsToRun {
            let urlString = baseUrl.absoluteString + filename + ".png"
            guard let url = URL(string: urlString) else {
                continue
            }
            
            let fs = FileManager.default
            if(fs.fileExists(atPath: url.absoluteString)){
                try? fs.removeItem(at: url)
            }
        }
    }
    
    func updateToNextRiveModel(){
        self.currentModelIndex += 1
        if self.currentModelIndex < self.modelsToRun.count{
            self.viewModel = RiveViewModel(fileName:self.modelsToRun[self.currentModelIndex], autoPlay: false)
            try! self.setModel(self.viewModel!.riveModel!)
            self.canRender = 1
        }
    }
}
