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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.1/RiveRuntime.xcframework.zip",
            checksum: "94e361b3f065c4388ca449be241ebdf733bb3344f6a34d08b972ad172b4ffdb3"
        ),
    ]
)
