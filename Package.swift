// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.6.1/RiveRuntime.xcframework.zip",
            checksum: "4435a4bcf7771ec5f81b0d9e35caca3a52f03c77363e623e298c2d2e9e1ccbce"
        )
    ]
)
