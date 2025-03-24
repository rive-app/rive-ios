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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.7.3/RiveRuntime.xcframework.zip",
            checksum: "b7858162e4bd2ae4013fc9f6de256da383a021fca05f1d0432dffbafad528250"
        )
    ]
)
