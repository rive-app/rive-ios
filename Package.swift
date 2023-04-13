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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.9/RiveRuntime.xcframework.zip",
            checksum: "eb39c29a5d331eb0ce645323818f2f9259e0981533eb28a757e1e6ad1408fc44"
        ),
    ]
)
