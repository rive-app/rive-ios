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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.3/RiveRuntime.xcframework.zip",
            checksum: "f711405838517eafddf344304de6b9af39ba50e13be70501c3c8d83f77102a53"
        ),
    ]
)
