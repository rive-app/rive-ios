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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.12/RiveRuntime.xcframework.zip",
            checksum: "9665449ceb82a24afaef55b8d88167251fb2175c78c7e8eda2bdeb14461d611d"
        ),
    ]
)
