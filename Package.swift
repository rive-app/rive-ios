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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.5.1/RiveRuntime.xcframework.zip",
            checksum: "15913b45abbada5b5f27a459154e482b883f455d06f95c5367997ef45fc5c7e7"
        ),
    ]
)
