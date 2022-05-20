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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.15/RiveRuntime.xcframework.zip",
            checksum: "33ca6a71f151c87d469b0d091df9faabbbabedec97d5c9868e6c8399718dddc0"
        ),
    ]
)
