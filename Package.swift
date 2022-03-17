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
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.15/RiveRuntime.xcframework.zip",
            checksum: "8a5cdac1e7742962a7ba427f0d8c39ba63d0c82f095730698151a3f5c309c840"
        ),
    ]
)
