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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.10/RiveRuntime.xcframework.zip",
            checksum: "488b73b05b1427a2a775e42f5c09029caa911c07a8a53b94656c6cee84d76db7"
        ),
    ]
)
