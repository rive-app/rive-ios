// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.3/RiveRuntime.xcframework.zip",
            checksum: "62042e2f7149fb2906d8417fdb9e6d9faa7b3cff638f2be45bde79debe4a2e8f"
        ),
    ]
)
