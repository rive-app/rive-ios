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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.26/RiveRuntime.xcframework.zip",
            checksum: "eabbedc2a1b25f13ea06fbf2080a2d25d4a3c88722690af49600eafd89e46241"
        ),
    ]
)
