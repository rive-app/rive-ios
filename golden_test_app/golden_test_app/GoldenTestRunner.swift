import Combine
import CoreImage
import Foundation
import ImageIO
import Metal
import RiveRuntime
import UniformTypeIdentifiers

@MainActor
final class GoldenTestRunner: ObservableObject {
    @Published private(set) var rive: Rive?

    private static let fileNames = ["vector", "dwarf", "text"]
    private static let size = CGSize(width: 860, height: 540)
    private static let gpuCanvasEnvironmentVariable = "RIVE_GOLDEN_ENABLE_GPU_CANVAS"
    private static let resultsFileName = "golden_results.json"

    private var hasStarted = false
    private var task: Task<Void, Never>?

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        task = Task {
            defer { task = nil }
            do {
                try await run()
            } catch {
                let status = Task.isCancelled
                    ? "Golden tests cancelled"
                    : "Golden tests failed: \(error.localizedDescription)"
                print("[GoldenTests] \(status)")
            }
        }
    }

    func cancel() {
        task?.cancel()
    }

    private func run() async throws {
        let directory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        // Remove previous results even when this run's configuration is invalid.
        for name in Self.fileNames.map({ "\($0).png" }) + [Self.resultsFileName] {
            let url = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }

        let enableGPUCanvas: Bool
        switch ProcessInfo.processInfo.environment[Self.gpuCanvasEnvironmentVariable] {
        case nil, "0": enableGPUCanvas = false
        case "1": enableGPUCanvas = true
        default:
            throw GoldenTestError("\(Self.gpuCanvasEnvironmentVariable) must be 0 or 1.")
        }

        let configuration: Worker.Configuration
        #if RIVE_CANVAS
        configuration = .init(enableGPUCanvas: enableGPUCanvas)
        #else
        guard !enableGPUCanvas else {
            throw GoldenTestError("GPU Canvas requires a RIVE_CANVAS build.")
        }
        configuration = .init()
        #endif

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw GoldenTestError("No Metal device available.")
        }
        let worker = Worker(device: device, configuration: configuration)
        let context = CIContext(mtlDevice: device)
        let gpuCanvasDescription = enableGPUCanvas ? "GPU Canvas enabled" : "GPU Canvas disabled"
        print("[GoldenTests] Starting golden tests at 860×540 (\(gpuCanvasDescription))")

        for name in Self.fileNames {
            try Task.checkCancellation()
            let url = directory.appendingPathComponent("\(name).png")
            rive = try await render(
                name,
                worker: worker,
                device: device,
                context: context,
                outputURL: url
            )
            print("[GoldenTests] Saved \(url.path)")
        }

        let results = GoldenTestResults(
            enableGPUCanvas: enableGPUCanvas,
            files: Self.fileNames.map { "\($0).png" },
            width: Int(Self.size.width),
            height: Int(Self.size.height)
        )
        try JSONEncoder().encode(results).write(
            to: directory.appendingPathComponent(Self.resultsFileName),
            options: .atomic
        )
        print("[GoldenTests] Completed all 3 golden tests (\(gpuCanvasDescription))")
    }

    private func render(
        _ name: String,
        worker: Worker,
        device: any MTLDevice,
        context: CIContext,
        outputURL: URL
    ) async throws -> Rive {
        let file = try await File(source: .local(name, .main), worker: worker)
        let rive = try await Rive(
            file: file,
            fit: .contain(alignment: .center),
            backgroundColor: RiveRuntime.Color(0)
        )
        let renderer = rive.makeRenderer()
        // Keep runtime handles and the per-surface renderer alive through GPU completion.
        defer { withExtendedLifetime((rive, renderer)) {} }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLRiveColorPixelFormat(),
            width: Int(Self.size.width),
            height: Int(Self.size.height),
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw GoldenTestError("Could not create texture for \(name).")
        }

        try Task.checkCancellation()
        rive.stateMachine.advance(by: 0)
        let configuration = RiveUIRendererConfiguration(rive: rive, drawableSize: Self.size)
        // Await each submission before submitting another; pending draws may be coalesced.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            renderer.draw(
                configuration,
                to: texture,
                from: device,
                onDraw: { commandBuffer in
                    commandBuffer.addCompletedHandler { completedBuffer in
                        if completedBuffer.status == .completed {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: GoldenTestError(
                                "GPU draw failed for \(name): \(completedBuffer.error?.localizedDescription ?? "unknown error")"
                            ))
                        }
                    }
                },
                onSkipped: {
                    continuation.resume(throwing: GoldenTestError("Draw unexpectedly skipped for \(name)."))
                },
                onError: { error in
                    continuation.resume(throwing: GoldenTestError("Could not draw \(name): \(error.localizedDescription)"))
                }
            )
        }
        try Task.checkCancellation()

        guard let image = CIImage(
            mtlTexture: texture,
            options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]
        ) else {
            throw GoldenTestError("Could not read texture for \(name).")
        }
        let flipped = image.transformed(by:
            CGAffineTransform(translationX: 0, y: Self.size.height).scaledBy(x: 1, y: -1)
        )
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = context.createCGImage(
                flipped,
                from: CGRect(origin: .zero, size: Self.size),
                format: .RGBA8,
                colorSpace: colorSpace
              ) else {
            throw GoldenTestError("Could not convert texture for \(name).")
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw GoldenTestError("Could not create PNG for \(name).")
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw GoldenTestError("Could not encode PNG for \(name).")
        }
        // Collectors must only see complete PNGs, never an unfinished write.
        try (data as Data).write(to: outputURL, options: .atomic)
        return rive
    }
}

private struct GoldenTestResults: Encodable {
    let enableGPUCanvas: Bool
    let files: [String]
    let width: Int
    let height: Int
}

private struct GoldenTestError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
