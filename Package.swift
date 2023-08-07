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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.6/RiveRuntime.xcframework.zip",
            checksum: "e53fea5aaa549b511b4a717f14bdd4872e573f13128da9947f2bde0454136427"
        ),
    ]
)
