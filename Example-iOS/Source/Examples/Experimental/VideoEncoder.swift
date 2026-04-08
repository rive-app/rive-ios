//
//  VideoEncoder.swift
//  RiveExample
//
//  Created by Cursor Assistant on 4/6/26.
//

import AVFoundation
import CoreImage
import Foundation
import Metal
@_spi(RiveExperimental) import RiveRuntime

enum VideoEncoderError: LocalizedError {
    case missingMetalDevice
    case setupFailed(String)
    case renderFailed(String)
    case writeFailed(frame: Int)
    case finishFailed(String)

    /// Returns a user-facing description for each encoder error case.
    var errorDescription: String? {
        switch self {
        case .missingMetalDevice:
            return "No Metal device available."
        case .setupFailed(let detail):
            return "Setup failed: \(detail)"
        case .renderFailed(let detail):
            return "Render error: \(detail)"
        case .writeFailed(let frame):
            return "Failed to write frame \(frame)."
        case .finishFailed(let detail):
            return "Failed to finalize video: \(detail)"
        }
    }
}

final class VideoEncoder {
    private struct UnsafeSendable<T>: @unchecked Sendable {
        let value: T
    }

    /// All state needed for the encode loop, so individual
    /// functions don't need long parameter lists.
    private struct Resources {
        let rive: Rive
        let renderer: Renderer
        let device: any MTLDevice
        let texture: any MTLTexture
        let writer: AVAssetWriter
        let writerInput: AVAssetWriterInput
        let adaptor: AVAssetWriterInputPixelBufferAdaptor
        let ciContext: CIContext
        let colorSpace: CGColorSpace
        let size: CGSize
        let frameDuration: TimeInterval
        let frameRate: Int
        let frameCount: Int
    }

    /// Exports a Rive animation to an MP4 file at a fixed frame rate.
    ///
    /// Steps:
    /// 1) Resolve shared platform resources (device/output path).
    /// 2) Build immutable encoding resources.
    /// 3) Run the encode loop off-main and return the output URL.
    @MainActor
    func export(
        rive: Rive,
        size: CGSize,
        duration: TimeInterval,
        frameRate: Int = 60,
        outputURL: URL? = nil,
        onProgress: (@MainActor (Double) -> Void)? = nil
    ) async throws -> URL {
        // Step 1: Resolve platform resources needed for encoding.
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw VideoEncoderError.missingMetalDevice
        }

        let outputURL = outputURL ?? Self.defaultOutputURL()

        // Step 2: Ensure the writer starts from a clean output path.
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        // Step 3: Build immutable resources once before running the frame loop.
        let resources = try Self.makeResources(
            rive: rive,
            renderer: Renderer(rive: rive),
            device: device,
            size: size,
            frameRate: frameRate,
            duration: duration,
            outputURL: outputURL
        )

        let wrappedResources = UnsafeSendable(value: resources)
        let wrappedProgress = UnsafeSendable(value: onProgress)

        // Step 4: Execute the frame loop off-main.
        return try await VideoEncoder.runDetachedEncode(
            resources: wrappedResources,
            outputURL: outputURL,
            onProgress: wrappedProgress
        )
    }

    // MARK: - Encode loop

    /// Encodes all frames and finalizes the writer.
    ///
    /// Steps:
    /// 1) Render and append every frame.
    /// 2) Send progress updates.
    /// 3) Finish writing and validate completion state.
    private static func encodeFrames(
        with resources: Resources,
        outputURL: URL,
        onProgress: (@MainActor (Double) -> Void)?
    ) async throws -> URL {
        // Step 1: Render and append each frame.
        for frameIndex in 0..<resources.frameCount {
            do {
                try await renderFrame(frameIndex, with: resources)
            } catch {
                resources.writerInput.markAsFinished()
                resources.writer.cancelWriting()
                throw error
            }

            // Step 2: Publish progress back on the main actor.
            if let onProgress {
                let progress = Double(frameIndex + 1) / Double(resources.frameCount)
                await MainActor.run { onProgress(progress) }
            }
        }

        // Step 3: Finalize the writer session.
        resources.writerInput.markAsFinished()
        await withCheckedContinuation { continuation in
            resources.writer.finishWriting { continuation.resume() }
        }

        // Step 4: Validate that finalization succeeded.
        if resources.writer.status != .completed {
            throw VideoEncoderError.finishFailed(
                resources.writer.error?.localizedDescription ?? "Unknown error"
            )
        }

        return outputURL
    }

    // MARK: - Per-frame

    /// Renders one frame, converts it to a pixel buffer, and appends it.
    ///
    /// Steps:
    /// 1) Advance the state machine and build a renderer configuration.
    /// 2) Submit draw commands and wait for GPU completion.
    /// 3) Convert texture -> pixel buffer and append to the writer.
    private static func renderFrame(
        _ frameIndex: Int,
        with resources: Resources
    ) async throws {
        // Step 1: Fixed-step advancement gives deterministic output independent of wall-clock time.
        let configuration = await MainActor.run { () -> RendererConfiguration in
            resources.rive.stateMachine.advance(by: resources.frameDuration)
            return RendererConfiguration(rive: resources.rive, drawableSize: resources.size)
        }

        // Step 2: Draw submission must happen on main; completion fires on the GPU timeline.
        try await submitDraw(configuration, with: resources)

        // Step 3a: Read rendered texture back into a pixel buffer for the writer.
        guard let pool = resources.adaptor.pixelBufferPool else {
            throw VideoEncoderError.setupFailed("Pixel buffer pool unavailable.")
        }
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard let pixelBuffer else {
            throw VideoEncoderError.setupFailed("Failed to create pixel buffer.")
        }

        guard let image = CIImage(
            mtlTexture: resources.texture,
            options: [.colorSpace: resources.colorSpace]
        ) else {
            throw VideoEncoderError.renderFailed("Failed to create CIImage from texture.")
        }

        // Step 3b: Flip vertically because Metal and video buffers have opposite Y origins.
        let flipped = image.transformed(
            by: CGAffineTransform(translationX: 0, y: resources.size.height).scaledBy(x: 1, y: -1)
        )

        resources.ciContext.render(
            flipped,
            to: pixelBuffer,
            bounds: CGRect(origin: .zero, size: resources.size),
            colorSpace: resources.colorSpace
        )

        // Step 3c: Respect AVAssetWriter backpressure before appending.
        while !resources.writerInput.isReadyForMoreMediaData {
            try await Task.sleep(nanoseconds: 1_000_000)
        }

        let timestamp = CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(resources.frameRate))
        guard resources.adaptor.append(pixelBuffer, withPresentationTime: timestamp) else {
            throw VideoEncoderError.writeFailed(frame: frameIndex)
        }
    }

    /// Submits a draw call to `Renderer` and resumes when the command buffer completes.
    @MainActor
    private static func submitDraw(
        _ configuration: RendererConfiguration,
        with resources: Resources
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            resources.renderer.draw(configuration, to: resources.texture, from: resources.device) { commandBuffer in
                commandBuffer.addCompletedHandler { _ in continuation.resume() }
                commandBuffer.commit()
            } onError: { error in
                continuation.resume(throwing: VideoEncoderError.renderFailed(error.localizedDescription))
            }
        }
    }

    /// Runs the encode loop in a detached task to keep heavy work off-main.
    private static func runDetachedEncode(
        resources: UnsafeSendable<Resources>,
        outputURL: URL,
        onProgress: UnsafeSendable<(@MainActor (Double) -> Void)?>
    ) async throws -> URL {
        let task = Task.detached(priority: .userInitiated) { () async throws -> URL in
            try await Self.encodeFrames(
                with: resources.value,
                outputURL: outputURL,
                onProgress: onProgress.value
            )
        }
        return try await task.value
    }

    // MARK: - Setup

    /// Creates all immutable objects used during encoding.
    ///
    /// Steps:
    /// 1) Normalize dimensions and create the Metal render texture.
    /// 2) Build AVAssetWriter pipeline (writer input + adaptor).
    /// 3) Start writer session and return a fully populated `Resources`.
    private static func makeResources(
        rive: Rive,
        renderer: Renderer,
        device: any MTLDevice,
        size: CGSize,
        frameRate: Int,
        duration: TimeInterval,
        outputURL: URL
    ) throws -> Resources {
        // Step 1: Normalize dimensions to integer pixel bounds.
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw VideoEncoderError.setupFailed("Failed to create render texture.")
        }

        // Step 2: Build AVAssetWriter and its input pipeline.
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw VideoEncoderError.setupFailed("Failed to create AVAssetWriter.")
        }

        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
        )
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
        )

        guard writer.canAdd(writerInput) else {
            throw VideoEncoderError.setupFailed("Writer cannot accept input.")
        }

        // Step 3: Start writing at t=0 and capture all immutable runtime resources.
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        return Resources(
            rive: rive,
            renderer: renderer,
            device: device,
            texture: texture,
            writer: writer,
            writerInput: writerInput,
            adaptor: adaptor,
            ciContext: CIContext(mtlDevice: device),
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            size: CGSize(width: width, height: height),
            frameDuration: 1.0 / Double(frameRate),
            frameRate: frameRate,
            frameCount: max(1, Int((duration * Double(frameRate)).rounded()))
        )
    }

    /// Returns a temporary file URL for encoded output.
    private static func defaultOutputURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("rive_video_\(UUID().uuidString).mp4")
    }
}
