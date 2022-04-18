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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.2/RiveRuntime.xcframework.zip",
            checksum: "3a7163e1d5846eb211181928ce5878eed360057901ea05cd9f2186a4a22a16bd"
        ),
    ]
)
