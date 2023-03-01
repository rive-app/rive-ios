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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.6/RiveRuntime.xcframework.zip",
            checksum: "27e01b43b1bfac57bf8040bfc264f9e4a179c17cb01935efa41e1aba8cb0f3ca"
        ),
    ]
)
