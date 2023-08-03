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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.2/RiveRuntime.xcframework.zip",
            checksum: "818bcdcfb02616e3029c61768dd60736068409e584b856ddef31f7169d6758f8"
        ),
    ]
)
