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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.1/RiveRuntime.xcframework.zip",
            checksum: "9e48dfde1bbd1fdf3bc4f874e64b5adbe9ef64c99cdb39fbe4f5d07e101939e7"
        ),
    ]
)
