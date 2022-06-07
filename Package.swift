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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.20/RiveRuntime.xcframework.zip",
            checksum: "0bdfbf3b761024247b1f187f239a279db38861bc0c31bbb95ed999ef18d29517"
        ),
    ]
)
