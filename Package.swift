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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.0.1/RiveRuntime.xcframework.zip",
            checksum: "024aaddc4ba8141187ebc63ccd806bff7dd5b14d4e1c7bffed1a5451c5624fa1"
        ),
    ]
)
