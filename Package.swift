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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.4.0/RiveRuntime.xcframework.zip",
            checksum: "8b8bacf378fc9dea33ac86ff121b8ece7d3a8e814b3200958d47f8eeb94c1658"
        ),
    ]
)
