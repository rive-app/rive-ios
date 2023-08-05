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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.3/RiveRuntime.xcframework.zip",
            checksum: "577d4b8538f0ff1fad45e34592cd73a6cd444abafc2d6fc05925ffd92cf07130"
        ),
    ]
)
