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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.18/RiveRuntime.xcframework.zip",
            checksum: "0203289df267bdb16610afe1602548fbf46574b2ce50e4174404bba5e6b36211"
        ),
    ]
)
