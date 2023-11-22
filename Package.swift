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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.6.2/RiveRuntime.xcframework.zip",
            checksum: "088affb4b3d776616b770dfbe3f189b1ae1120498fbf53161cf76ad04fcb1556"
        ),
    ]
)
