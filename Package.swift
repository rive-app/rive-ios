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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.3/RiveRuntime.xcframework.zip",
            checksum: "fb3cb91b2e55920beb4b47c8b0a93cfa53635cc58707b0802dc539ea44a55314"
        ),
    ]
)
