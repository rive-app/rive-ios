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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.12/RiveRuntime.xcframework.zip",
            checksum: "f696d589e2f5d599512717a022a8518e1e12fb8389718d817f56efd0cd695a62"
        ),
    ]
)
