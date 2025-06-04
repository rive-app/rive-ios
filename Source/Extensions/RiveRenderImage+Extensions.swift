//
//  RiveRenderImage+Extensions.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/22/25.
//  Copyright © 2025 Rive. All rights reserved.
//

public extension RiveRenderImage {
    enum Format {
        case jpeg(compressionQuality: CGFloat)
        case png
    }

    #if canImport(UIKit)
    convenience init?(image: UIImage, format: Format) {
        let data: Data?
        switch format {
        case .jpeg(let compressionQuality):
            data = image.jpegData(compressionQuality: compressionQuality)
        case .png:
            data = image.pngData()
        }
        guard let data else { return nil }
        self.init(data: data)
    }
    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    convenience init?(image: NSImage, format: Format) {
        guard let data = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: data)
        else { return nil }

        let bitmapData: Data?
        switch format {
        case .jpeg(let compressionQuality):
            // Double(compressionQuality) will bridge to NSNumber, as required by .compressionFactor
            bitmapData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: Double(compressionQuality)])
        case .png:
            bitmapData = bitmap.representation(using: .png, properties: [:])
        }
        guard let bitmapData else { return nil }
        self.init(data: bitmapData)
    }
    #endif
}
