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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.6.0/RiveRuntime.xcframework.zip",
            checksum: "467be7bbee8456df07b680c63140923e386fe4897adfc37074f1bc167eb67ba0"
        ),
    ]
)
