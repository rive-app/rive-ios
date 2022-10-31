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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.6/RiveRuntime.xcframework.zip",
            checksum: "cbf8534354c396d93a3a2510260b156e710a8cffe922f7c70524745713d73269"
        ),
    ]
)
