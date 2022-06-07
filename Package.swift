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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.22/RiveRuntime.xcframework.zip",
            checksum: "f0f97d06d848853e611dcc3257897de93f4d2ff681b8838f41d773154e88a413"
        ),
    ]
)
