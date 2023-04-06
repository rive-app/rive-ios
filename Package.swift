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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.8/RiveRuntime.xcframework.zip",
            checksum: "c999ef3644c57ce6d1efba1444ac1d35850f0c9f81abbd4ec668f638984c9b36"
        ),
    ]
)
