//
//  VideoEncoderView.swift
//  RiveExample
//
//  Created by Cursor Assistant on 4/6/26.
//

import AVKit
import SwiftUI
@_spi(RiveExperimental) import RiveRuntime

struct VideoEncoderView: View {
    @State private var progress: Double = 0
    @State private var isRendering = false
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    @State private var renderTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text("Failed to render video")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        startRenderIfNeeded(force: true)
                    }
                }
                .padding(24)
            } else {
                Color.black.ignoresSafeArea()
            }

            if isRendering {
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    Text("Encoding \(Int((progress * 100).rounded()))%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("Video Encoder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startRenderIfNeeded()
        }
        .onDisappear {
            renderTask?.cancel()
            renderTask = nil
            player?.pause()
        }
    }

    private func startRenderIfNeeded(force: Bool = false) {
        if !force, renderTask != nil || isRendering || player != nil {
            return
        }

        renderTask?.cancel()
        renderTask = Task {
            await renderVideo()
        }
    }

    @MainActor
    private func renderVideo() async {
        isRendering = true
        progress = 0
        errorMessage = nil
        player = nil
        defer {
            isRendering = false
            renderTask = nil
        }

        do {
            let worker = try await Worker()
            let file = try await File(source: .local("marty_v2", .main), worker: worker)
            let rive = try await Rive(file: file)

            let encoder = VideoEncoder()
            let videoURL = try await encoder.export(
                rive: rive,
                size: CGSize(width: 1080, height: 1920),
                duration: 5,
                frameRate: 60,
                onProgress: { progress in
                    self.progress = progress
                }
            )

            guard !Task.isCancelled else {
                return
            }

            let player = AVPlayer(url: videoURL)
            self.player = player
            player.play()
        } catch {
            if Task.isCancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
}
