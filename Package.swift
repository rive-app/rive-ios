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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.13/RiveRuntime.xcframework.zip",
            checksum: "aae162691044d0afa6d431ae535db8a601fbeeaf8a3a7c5bd8ad92ed11c4497f"
        ),
    ]
)
