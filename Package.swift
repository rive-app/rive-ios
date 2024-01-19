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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.7.1/RiveRuntime.xcframework.zip",
            checksum: "3c3f388e8cef615ce4cc680bc086fddd1e1fc9426c0d54faa2c96a1d6d7c2079"
        ),
    ]
)
