// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.17/RiveRuntime.xcframework.zip",
            checksum: "663111d803275e38bb0e41af7bca73db9b70830db120e47cd18bb46c6368c1d7"
        ),
    ]
)
