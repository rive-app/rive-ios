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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.11/RiveRuntime.xcframework.zip",
            checksum: "4b59aa2cc9624a3486de89dd1ef49d5bae03546979bd01dce44621bf9e080f38"
        ),
    ]
)
