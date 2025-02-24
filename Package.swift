// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.7.1/RiveRuntime.xcframework.zip",
            checksum: "bb43087a209a1df7f20bcdfb86e9eb6cb4ea846f4de199ffa171cc58c4da430a"
        )
    ]
)
