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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.25/RiveRuntime.xcframework.zip",
            checksum: "e9d07548baebfb53acd540b607c80c9ab372e9d7ff68fd806cde0757660fd435"
        ),
    ]
)
