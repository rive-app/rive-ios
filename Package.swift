// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.24/RiveRuntime.xcframework.zip",
            checksum: "82f5dd8e0ac9324b82f505807d9827ef6cb4d7a74c315a58ca303b6634201a54"
        ),
    ]
)
