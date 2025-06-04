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
}
