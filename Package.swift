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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.2.0/RiveRuntime.xcframework.zip",
            checksum: "4f0d2044bae2a61c4e8169bf358b1e6b5b236863af102bebcae534a2d7311245"
        ),
    ]
)
