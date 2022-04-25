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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.4/RiveRuntime.xcframework.zip",
            checksum: "9a3e50e11723c68e00e6da68706be088d166abbe601fcacfa91d91bcd1f19ff7"
        ),
    ]
)
