// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.0/RiveRuntime.xcframework.zip",
            checksum: "15caabbda712fa22788acc545d8087ca64410cf490c020cfc251e4b4a619c091"
        ),
    ]
)
