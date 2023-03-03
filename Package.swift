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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.7/RiveRuntime.xcframework.zip",
            checksum: "1dca2f894971cec04baa2d9878279af9b6027ca9097bc6dbad481f559b180104"
        ),
    ]
)
