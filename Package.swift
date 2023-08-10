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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.5/RiveRuntime.xcframework.zip",
            checksum: "d3b3951b5d1fb62655a294b7fcbed80be86f36d28d3d4c13aa8bddb275435d12"
        ),
    ]
)
