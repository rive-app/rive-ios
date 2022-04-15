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
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.18/RiveRuntime.xcframework.zip",
            checksum: "639e3811098d62362a6c21a1438fb5c746de8e28a62afce76af5cb09c1e10a9c"
        ),
    ]
)
