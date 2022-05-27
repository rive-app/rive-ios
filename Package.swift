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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.19/RiveRuntime.xcframework.zip",
            checksum: "f8e27ac0c8540057d6f26548b24d5cacac6fc18c5259a0a9153d5bfa0265622a"
        ),
    ]
)
