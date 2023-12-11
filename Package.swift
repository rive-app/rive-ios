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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.7.0/RiveRuntime.xcframework.zip",
            checksum: "14c5acf640cbc8a04caf47bcc5b485863c717a52be9ac40cdf316e8b9f44c17b"
        ),
    ]
)
