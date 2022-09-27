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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.3/RiveRuntime.xcframework.zip",
            checksum: "e4fac6fdfbfac0aae38d6d46d1cec7b68849bd05e97eb0a02f7bdf24e1bf4dfe"
        ),
    ]
)
