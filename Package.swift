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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.2/RiveRuntime.xcframework.zip",
            checksum: "8a76647455abb9c6a2961c0a329c939669d7689744596710ebb01a1e45e497d1"
        ),
    ]
)
