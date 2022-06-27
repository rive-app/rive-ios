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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.27/RiveRuntime.xcframework.zip",
            checksum: "7bf42854eb1431f03b00e70e5b0f2cf414e0cde0952d4ed9cf52156f3bd22dc8"
        ),
    ]
)
