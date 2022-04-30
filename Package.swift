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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.9/RiveRuntime.xcframework.zip",
            checksum: "a39c7d4290d536c25cb86fa13c9a95975dc594efc148034cef0a970d9859ae2d"
        ),
    ]
)
