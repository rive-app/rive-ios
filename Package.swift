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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.16/RiveRuntime.xcframework.zip",
            checksum: "f3c5935f8514ee63bd1fc7706f6a74969cb136c9076f3fe3024b84fc38383b5d"
        ),
    ]
)
