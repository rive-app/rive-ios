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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.3.0/RiveRuntime.xcframework.zip",
            checksum: "916b736c582cc57c5b423f0d2ba09e07de7b1a4ec292fb661bb4b7978f9a95d3"
        ),
    ]
)
