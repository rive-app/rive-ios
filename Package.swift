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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.3.1/RiveRuntime.xcframework.zip",
            checksum: "8b76e6d2496089b4a71abedf1437c921b62fbd133c6185e5421deaa67a23e358"
        ),
    ]
)
