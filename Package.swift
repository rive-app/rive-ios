// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.13/RiveRuntime.xcframework.zip",
            checksum: "b43ae3f3cc49d1240ac865f62d422e44cedab2b8e4b3a9b0889e4de4a1caea36"
        ),
    ]
)
