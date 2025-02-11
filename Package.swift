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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.6.0/RiveRuntime.xcframework.zip",
            checksum: "b81cbee805f7cc2e69c6d413092fe7f780c941a8df5ada5944a7fe7dad356d35"
        )
    ]
)
