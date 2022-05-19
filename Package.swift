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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.14/RiveRuntime.xcframework.zip",
            checksum: "723517d4e98c8b1f479c5ecfdd0d3fbd801eff3f84c9c9e738158cf632e5c10b"
        ),
    ]
)
