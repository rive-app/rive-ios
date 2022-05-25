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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.17/RiveRuntime.xcframework.zip",
            checksum: "5c150bfc7a07de6a09348b0ce28ff2a6a093d8a7781589e483be8d71426c1203"
        ),
    ]
)
