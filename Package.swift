// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.16/RiveRuntime.xcframework.zip",
            checksum: "e55c1edf888210dc983c83328c8c9b4c93e43fb9b8e5dfc36212721b957c86fb"
        ),
    ]
)
