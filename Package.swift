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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.11.1/RiveRuntime.xcframework.zip",
            checksum: "89e0931bd0022d82a21af2d937be07398648a0f8e69eda7da56452a55890c683"
        ),
    ]
)
