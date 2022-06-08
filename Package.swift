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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.23/RiveRuntime.xcframework.zip",
            checksum: "ef8e35f75fb11875eebc1a818f17848dae3fa2122047dc5d89d271f59dfc1828"
        ),
    ]
)
