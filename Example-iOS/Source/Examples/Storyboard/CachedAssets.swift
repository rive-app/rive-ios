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


class AssetLoader{
    init() {
        factory = RenderContextManager.shared()!.getDefaultFactory();
        fillFontCache();
        fillImageCache();
    }
    var imageCache: [RiveRenderImage] = [];
    var fontCache: [RiveFont] = [];
    
    var onDemandFont: RiveFontAsset?;
    var onDemandImage: RiveImageAsset?;
    var cachedFont: RiveFontAsset?;
    var cachedImage: RiveImageAsset?;
    var factory: RiveFactory?;

    // pretty naive way to clean up any outstanding requests.
    var tasks: [URLSessionDataTask] = [];
    
    func fillFontCache(){
        let options = [
            "https://cdn.rive.app/runtime/flutter/IndieFlower-Regular.ttf",
            "https://cdn.rive.app/runtime/flutter/comic-neue.ttf",
            "https://cdn.rive.app/runtime/flutter/inter.ttf",
            "https://cdn.rive.app/runtime/flutter/inter-tight.ttf",
            "https://cdn.rive.app/runtime/flutter/josefin-sans.ttf",
            "https://cdn.rive.app/runtime/flutter/send-flowers.ttf",
        ]
        var first = true;
        
        for option in options {
            let url = URL(string: option)!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                
                if let data = data {
                    self.fontCache.append(self.factory!.decodeFont(data));
                }
                
                if (first){
                    first=false;
                    if let fontAsset = self.cachedFont, let font=self.fontCache.randomElement() {
                        fontAsset.font(font);
                    }
                }
                
            }
            task.resume()
            tasks.append(task)
        }
    }
    
    func fillImageCache(){
        var i = 0;
        var first = true;
        
        repeat  {
            let url = URL(string: "https://picsum.photos/2048/1365")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    self.imageCache.append(self.factory!.decodeImage(data));
                }
                if (first){
                    first=false;
                    if let imageAsset = self.cachedImage, let image=self.imageCache.randomElement() {
                        imageAsset.renderImage(image);
                    }
                }
            }
            task.resume()
            tasks.append(task)
            i += 1;
        } while (i < 10)
        
        
    }
    
    
    func cachedFontAsset(asset: RiveFontAsset) {
        if let font = fontCache.randomElement() {
            asset.font(font);
        }
        
    }
    func cachedImageAsset(asset: RiveImageAsset) {
        if let image = imageCache.randomElement() {
            asset.renderImage(image);
        }
    }
    
    func randomFontAsset(asset: RiveFontAsset, factory: RiveFactory){
        let options = [
            "https://cdn.rive.app/runtime/flutter/IndieFlower-Regular.ttf",
            "https://cdn.rive.app/runtime/flutter/comic-neue.ttf",
            "https://cdn.rive.app/runtime/flutter/inter.ttf",
            "https://cdn.rive.app/runtime/flutter/inter-tight.ttf",
            "https://cdn.rive.app/runtime/flutter/josefin-sans.ttf",
            "https://cdn.rive.app/runtime/flutter/send-flowers.ttf",
        ]
        let url = URL(string: options.randomElement()!)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                asset.font(factory.decodeFont(data));
            } else if let error = error {
                if (error.localizedDescription != "cancelled"){
                    print("HTTP Request Failed \(error)")
                }
            }
        }
        task.resume()
        tasks.append(task)
    }
    
    func randomImageAsset(asset: RiveImageAsset, factory: RiveFactory){
        let url = URL(string: "https://picsum.photos/1000/1500")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                
                asset.renderImage(factory.decodeImage(data));
            } else if let error = error {
                // there doesnt seem to be much else to go on here
                if (error.localizedDescription != "cancelled"){
                    print("HTTP Request Failed \(error)")
                }
            }
        }
        
        task.resume()
        tasks.append(task)
    }
    
    func loader (asset: RiveFileAsset, data: Data, factory: RiveFactory) -> Bool{
        if (data.count > 0) {return false;}
        if (asset.cdnUuid().count > 0) {return false;}
        
        switch (asset.name()) {
            
            
        case "flower.jpeg",
            "three.png":
            onDemandImage = (asset as! RiveImageAsset);
            randomImageAsset(asset: onDemandImage!, factory: factory);
            return true;
        case "tree.jpg":
            cachedImage = (asset as! RiveImageAsset);
            cachedImageAsset(asset: cachedImage!);
            return true;
        case "Kenia",
            "Inter":
            onDemandFont = (asset as! RiveFontAsset);
            randomFontAsset(asset: (asset as! RiveFontAsset), factory: factory);
            return true;
        case "Kodchasan":
            cachedFont = (asset as! RiveFontAsset);
            cachedFontAsset(asset: cachedFont!);
            return true;
        default: break
        }
        return false;
    }
    
    func shuffle(){
        if let asset=onDemandImage, let factory=factory{
            randomImageAsset(asset: (asset), factory: factory);
        }
        if let asset=onDemandFont, let factory=factory{
            randomFontAsset(asset: (asset), factory: factory);
        }
        if let asset=cachedFont, let font=fontCache.randomElement(){
            asset.font(font)
        }
        if let asset=cachedImage, let image=imageCache.randomElement(){
            asset.renderImage(image)
        }
    }
    func cleanup(){
        for task in tasks {
            task.cancel();
        }
    }
}


class OutOfBandAssetsController: UIViewController, UIGestureRecognizerDelegate {
    //    TODO: talk to people to see if we can make this nice...
    var loader: AssetLoader = AssetLoader();
    var viewModel: RiveViewModel?;
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loader.cleanup()
    }
    
    
    required init?(coder: NSCoder) {
        self.viewModel = RiveViewModel(fileName: "asset_load_check", loadCdn: true, customLoader: loader.loader);
        super.init(coder: coder);
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let riveView = viewModel!.createRiveView()
        view.addSubview(riveView)
        riveView.frame = view.frame
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.tap (_:)))
        self.view.addGestureRecognizer(gesture)
        riveView.addGestureRecognizer(gesture)
        
    }
    
    @objc func tap(_ sender:UITapGestureRecognizer) {
        loader.shuffle()
    }
}
