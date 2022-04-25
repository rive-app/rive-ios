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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.5/RiveRuntime.xcframework.zip",
            checksum: "0096cd5891cb221cc69d3294fb218b5ca376c7c9e6e0efbe5c99b123b72c0356"
        ),
    ]
)
