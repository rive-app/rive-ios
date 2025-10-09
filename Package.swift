// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1"), .macCatalyst("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.12.0/RiveRuntime.xcframework.zip",
            checksum: "9bc6fe1c01a9fc2a33f4bf437d156fcc5b00c1b834d0a8c018a8a603630a5419"
        )
    ]
)
