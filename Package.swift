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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.7/RiveRuntime.xcframework.zip",
            checksum: "3a099a3f2b1eeada1a17ed1e0f9f742323797d872f2982c2a9ee359c80792dcf"
        ),
    ]
)
