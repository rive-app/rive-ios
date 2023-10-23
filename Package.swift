// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/5.5.0/RiveRuntime.xcframework.zip",
            checksum: "bfab3f6691fc678ba4a059a0fb80fada4dcc5e14bce837ee46dd6d42b5a7b201"
        ),
    ]
)
