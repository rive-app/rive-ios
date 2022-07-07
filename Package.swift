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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.1/RiveRuntime.xcframework.zip",
            checksum: "2fc68a89e6c034ca220e08506e8d4e2f62c7c24e95ee4f5bbc60075877c3c557"
        ),
    ]
)
