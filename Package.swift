// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.1/RiveRuntime.xcframework.zip",
            checksum: "8182923536eb2452e41414adaeb65d9957d7ee30d0ddf4f298401fbe2e27ebef"
        ),
    ]
)
