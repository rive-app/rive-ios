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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.8.0/RiveRuntime.xcframework.zip",
            checksum: "de123ca56e7d9ea3726c728f0f1fa1cca9fc18eca5bcb9530146c5c28af31150"
        ),
    ]
)
