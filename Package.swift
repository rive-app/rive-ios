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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.2/RiveRuntime.xcframework.zip",
            checksum: "c702966031386d06f4f7b5b11da3b8972ad1176910550c9204c150779183d4fe"
        ),
    ]
)
