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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.5/RiveRuntime.xcframework.zip",
            checksum: "e743e2fa61d18ed20a3597837a9afb192542c88ed822794c6490a5bd9738b2c0"
        ),
    ]
)
