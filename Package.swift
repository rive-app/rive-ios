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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.6/RiveRuntime.xcframework.zip",
            checksum: "9eb03dcc61e35f3792d3199e440b1414cb7d6743bfd38db065cf26f6c623fbf0"
        ),
    ]
)
