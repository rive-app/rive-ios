// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1"), .macCatalyst("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.19.1/RiveRuntime.xcframework.zip",
            checksum: "86e18eff6652d7cbbad5a23ba8590ef3fef5bb7bee1b4c0693e860b549f364e3"
        )
    ]
)
