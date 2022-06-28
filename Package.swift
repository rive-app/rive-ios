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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.28/RiveRuntime.xcframework.zip",
            checksum: "a7b26f4da457c94d88976eeccaca0f9a4a7da632b96f4b7bfc22387a2e0f935d"
        ),
    ]
)
