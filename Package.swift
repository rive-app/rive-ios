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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.5/RiveRuntime.xcframework.zip",
            checksum: "b8f946e0bb599fc619cbe1b996d19e51a7848b40b6ca0b776037e0d994bcd1f1"
        ),
    ]
)
