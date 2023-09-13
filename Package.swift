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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.2.1/RiveRuntime.xcframework.zip",
            checksum: "19770579bea60d3ae1753c8be469909154508e84b880133b4437de2d8235d4f5"
        ),
    ]
)
