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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.8/RiveRuntime.xcframework.zip",
            checksum: "5e4e8b410abaeaac656e1bcde64114b7c7130416ab508a92a99eba5b16b08142"
        ),
    ]
)
