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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.5/RiveRuntime.xcframework.zip",
            checksum: "e10279385e1abfde07a71cbbe066e811e68bf72cb9e1e1e8fe4e8eb064841884"
        ),
    ]
)
