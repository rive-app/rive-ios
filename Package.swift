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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.3.2/RiveRuntime.xcframework.zip",
            checksum: "a69a166d6d96fe0d61bf4939a29e643994060e0094414158403df0698178beec"
        ),
    ]
)
