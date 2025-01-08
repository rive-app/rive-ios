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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.5.6/RiveRuntime.xcframework.zip",
            checksum: "9bfee9ccf33046c24cb1dddd3c24b3d3573f42601b459a960a8d88c71584f5b7"
        )
    ]
)
