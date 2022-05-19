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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.13/RiveRuntime.xcframework.zip",
            checksum: "593b971e108329b763cef4cf45750a20cbfaad17b20e0ce2a52b6653a5efc4b0"
        ),
    ]
)
