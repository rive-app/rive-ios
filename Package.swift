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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.6/RiveRuntime.xcframework.zip",
            checksum: "21c7b3c28a025132d53f44971323dfcd31e1dd14153128799b46073ccad042e0"
        ),
    ]
)
