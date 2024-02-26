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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.9.1/RiveRuntime.xcframework.zip",
            checksum: "932ed341fd048c254b193d86ab68a0106d48a567a9a53e4169d3fea0e3aa129a"
        ),
    ]
)
