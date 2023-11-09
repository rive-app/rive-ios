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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.6.1/RiveRuntime.xcframework.zip",
            checksum: "dbc6135792fd5c8d226316c20d7da1b0062e0c9679a0c96ba1d4f1c08175a4c3"
        ),
    ]
)
