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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.4/RiveRuntime.xcframework.zip",
            checksum: "7b131545078a8e4244c92b80f96e10b3e8afd775ffe39fa225e32de402340cd5"
        ),
    ]
)
