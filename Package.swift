// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.1/RiveRuntime.xcframework.zip",
            checksum: "24b535c4b7e324404d76df806bc7a0fde6b6f3f436e10390f3e0d4854afb3bcb"
        ),
    ]
)
