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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.6.3/RiveRuntime.xcframework.zip",
            checksum: "88a9f910a79f6eb471e1712d46d79240224141db4a13a1dec72fad2d5b9b5ead"
        ),
    ]
)
