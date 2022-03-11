// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.12/RiveRuntime.xcframework.zip",
            checksum: "e53170b7025d91960031495f22cec298abede6431cba316ad5752bc4669b2dd6"
        ),
    ]
)
