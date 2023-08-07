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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.1.4/RiveRuntime.xcframework.zip",
            checksum: "9f122af510fa44b1804c7e4b9aa3ed5c0167567224ec36cc006eaf6abfe6ae4d"
        ),
    ]
)
