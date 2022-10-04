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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.0.4/RiveRuntime.xcframework.zip",
            checksum: "bad9e6c7adbe0be06969b8d680304391fab091eca7ebf69b82474978620c7275"
        ),
    ]
)
