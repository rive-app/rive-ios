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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.10.0/RiveRuntime.xcframework.zip",
            checksum: "3afb59a77378a7e51cdf82a98b926581a3a548900017dc520984452d7a03bf4a"
        ),
    ]
)
