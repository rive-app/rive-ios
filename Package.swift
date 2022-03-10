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
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.11/RiveRuntime.xcframework.zip",
            checksum: "fe08f9cfdca4c2070d66e5314a187e0c3c7aa0dde959d43f93a9bb9d604f5d90"
        ),
    ]
)
