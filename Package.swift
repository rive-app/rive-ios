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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.4/RiveRuntime.xcframework.zip",
            checksum: "da56812cd7a0329828e7d87a27edfa85253e86ef1f5c637397af30a028ba0256"
        ),
    ]
)
