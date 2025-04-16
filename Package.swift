// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.8.0/RiveRuntime.xcframework.zip",
            checksum: "8590d958397a6064c10eae2803ecc03cecc5f3b45a5170aed0b9fc21ef2773a5"
        )
    ]
)
