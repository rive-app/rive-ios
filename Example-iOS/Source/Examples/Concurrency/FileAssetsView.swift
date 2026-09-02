//
//  FileAssetsView.swift
//  RiveExample
//
//  Created by David Skuza on 6/15/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

private let imageAssetNames: Set<String> = [
    "flower.jpeg",
    "sloth.jpg",
]

private func loadAssetData(from url: URL) async throws -> Data {
    try await Task.detached(priority: .userInitiated) {
        try Data(contentsOf: url)
    }.value
}

private func loadImageData(for asset: File.Asset) async throws -> Data {
    let url: URL
    switch asset.name {
    case "flower.jpeg":
        url = URL(string: "https://picsum.photos/id/152/1000/1500")!
    case "sloth.jpg":
        guard let cdn = asset.cdn,
              let baseURL = URL(string: cdn.baseURL)
        else {
            throw URLError(.badURL)
        }
        url = baseURL.appendingPathComponent(cdn.uuid)
    default:
        throw URLError(.unsupportedURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    guard let response = response as? HTTPURLResponse,
          (200..<300).contains(response.statusCode)
    else {
        throw URLError(.badServerResponse)
    }
    return data
}

private struct DecodedImageAsset {
    let name: String
    let image: RiveRuntime.Image

    @MainActor
    func apply(to worker: Worker) {
        worker.addGlobalImageAsset(image, name: name)
    }

    @MainActor
    func clear(from worker: Worker) {
        worker.removeGlobalImageAsset(name: name)
    }
}

private struct DecodedFontAsset {
    let name: String
    let font: RiveRuntime.Font

    @MainActor
    func apply(to worker: Worker) {
        worker.addGlobalFontAsset(font, name: name)
    }

    @MainActor
    func clear(from worker: Worker) {
        worker.removeGlobalFontAsset(name)
    }
}

private final class FileAssetsViewModel: ObservableObject {
    @Published private(set) var rive: Rive?
    @Published private(set) var status = "Loading file without global assets…"
    @Published private(set) var globalsAreApplied = false
    @Published private(set) var isPreparingAssets = false
    @Published private(set) var assetsAreReady = false

    private var worker: Worker?
    private var decodedImages: [DecodedImageAsset] = []
    private var decodedFonts: [DecodedFontAsset] = []

    func load() {
        Task { @MainActor in
            do {
                let worker = try await Worker()
                let file = try await File(
                    source: .local("asset_load_check", .main),
                    worker: worker
                )
                let rive = try await Rive(file: file)

                self.worker = worker
                self.rive = rive
                self.isPreparingAssets = true
                self.status = "File loaded; downloading images…"

                do {
                    let assets = try await file.getAssets()
                    let imageAssets = assets.filter {
                        $0.type == .image && imageAssetNames.contains($0.name)
                    }
                    var decodedImages: [DecodedImageAsset] = []
                    for asset in imageAssets {
                        let data = try await loadImageData(for: asset)
                        decodedImages.append(
                            DecodedImageAsset(
                                name: asset.uniqueName,
                                image: try await worker.decodeImage(from: data)
                            )
                        )
                    }

                    guard let fontURL = Bundle.main.url(
                        forResource: "Inter-45562",
                        withExtension: "ttf"
                    ) else {
                        throw URLError(.fileDoesNotExist)
                    }

                    let fontData = try await loadAssetData(from: fontURL)
                    let font = try await worker.decodeFont(from: fontData)
                    let decodedFonts: [DecodedFontAsset] = assets.compactMap { asset in
                        guard asset.type == .font else {
                            return nil
                        }
                        return DecodedFontAsset(
                            name: asset.uniqueName,
                            font: font
                        )
                    }

                    self.decodedImages = decodedImages
                    self.decodedFonts = decodedFonts
                    self.assetsAreReady = true
                    self.isPreparingAssets = false
                    self.status = "File loaded; \(decodedImages.count) images ready"
                } catch {
                    self.isPreparingAssets = false
                    self.status = "File loaded; failed to prepare assets: \(error)"
                }
            } catch {
                self.status = "Failed to load: \(error)"
            }
        }
    }

    @MainActor
    func applyGlobals() {
        guard let worker else {
            return
        }
        for image in decodedImages {
            image.apply(to: worker)
        }
        for font in decodedFonts {
            font.apply(to: worker)
        }
        globalsAreApplied = true
        status = "Applied \(decodedImages.count) images and fonts"
    }

    @MainActor
    func clearGlobals() {
        guard let worker else {
            return
        }
        for image in decodedImages {
            image.clear(from: worker)
        }
        // Font removal is sent too, but rendered text currently retains its
        // cached font. That behavior will be addressed separately.
        for font in decodedFonts {
            font.clear(from: worker)
        }
        globalsAreApplied = false
        status = "Cleared global assets"
    }
}

struct FileAssetsView: View {
    @StateObject private var viewModel = FileAssetsViewModel()

    var body: some View {
        VStack(spacing: 12) {
            if let rive = viewModel.rive {
                RiveUIViewRepresentable(rive: rive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text(viewModel.status)
                .font(.caption)
                .multilineTextAlignment(.center)

            HStack {
                Button(viewModel.isPreparingAssets ? "Downloading images…" : "Apply assets after load") {
                    viewModel.applyGlobals()
                }
                .disabled(!viewModel.assetsAreReady)

                Button("Clear assets") {
                    viewModel.clearGlobals()
                }
                .disabled(!viewModel.globalsAreApplied)
            }

        }
        .padding()
        .task {
            viewModel.load()
        }
    }
}
