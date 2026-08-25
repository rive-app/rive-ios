//
//  FileAssetsView.swift
//  RiveExample
//
//  Created by David Skuza on 6/15/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

private func loadAssetData(from url: URL) async throws -> Data {
    try await Task.detached(priority: .userInitiated) {
        try Data(contentsOf: url)
    }.value
}

struct FileAssetsView: View {
    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(source: .local("simple_assets", .main), worker: worker)

            let assets = try await file.getAssets()
            for asset in assets {
                switch asset.type {
                case .image:
                    guard let url = Bundle.main.url(forResource: asset.uniqueName, withExtension: asset.fileExtension) else { continue }
                    let data = try await loadAssetData(from: url)
                    let image = try await worker.decodeImage(from: data)
                    worker.addGlobalImageAsset(image, name: asset.uniqueName)
                case .font:
                    guard let url = Bundle.main.url(forResource: asset.uniqueName, withExtension: asset.fileExtension) else { continue }
                    let data = try await loadAssetData(from: url)
                    let font = try await worker.decodeFont(from: data)
                    worker.addGlobalFontAsset(font, name: asset.uniqueName)
                case .audio:
                    guard let url = Bundle.main.url(forResource: asset.uniqueName, withExtension: asset.fileExtension) else { continue }
                    let data = try await loadAssetData(from: url)
                    let audio = try await worker.decodeAudio(from: data)
                    worker.addGlobalAudioAsset(audio, name: asset.uniqueName)
                case .unknown:
                    break
                }
            }

            return try await Rive(file: file)
        }
    }
}
