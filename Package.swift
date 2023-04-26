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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.11/RiveRuntime.xcframework.zip",
            checksum: "992a2dfcd1ea92b1ff163d866cbd18405e8bae118d1289014a23fbc95ab58299"
        ),
    ]
)
