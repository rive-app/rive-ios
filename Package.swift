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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.21/RiveRuntime.xcframework.zip",
            checksum: "2dd90bed3f909c2f8764cad53bf1e3eb5e6a96d3dcdcb9948133fd1ce585d919"
        ),
    ]
)
