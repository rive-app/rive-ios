// swift-tools-version:5.9
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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.9.1/RiveRuntime.xcframework.zip",
            checksum: "d9f76bc0d313c380cee8b774d887c5309b74cf8f376b0a1ff2154ea275ba36a1"
        )
    ]
)
