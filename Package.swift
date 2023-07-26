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
            url: "https://github.com/rive-app/rive-ios/releases/download/4.0.6/RiveRuntime.xcframework.zip",
            checksum: "77774bdce4574c45a2b463ab1b0224edc8820e16c8044e39f7ac4343f8ab9768"
        ),
    ]
)
