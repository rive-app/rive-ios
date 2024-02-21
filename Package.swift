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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.9.0/RiveRuntime.xcframework.zip",
            checksum: "0b1b0a6a687d0ea74d68b6ccb9eb70c6ffb5888767f164b717f1ee5e01ab4866"
        ),
    ]
)
