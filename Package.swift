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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.9/RiveRuntime.xcframework.zip",
            checksum: "38b230e1f5ea2eb46654fee1356288f6a0d053b90eabc0b6e49087b4e304097b"
        ),
    ]
)
