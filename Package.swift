// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/5.11.0/RiveRuntime.xcframework.zip",
            checksum: "2be7579bc11a38b630976de4503082ce41e64b7f3c1ef2a93dafc9b5f3b93001"
        ),
    ]
)
