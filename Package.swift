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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.2/RiveRuntime.xcframework.zip",
            checksum: "f69f7dc642671ff040ae7fff52c1cc9aef1b2c3daddb958c1e792804e97d202b"
        ),
    ]
)
