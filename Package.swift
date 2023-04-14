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
            url: "https://github.com/rive-app/rive-ios/releases/download/3.1.10/RiveRuntime.xcframework.zip",
            checksum: "de1fd0ca38d7e002f2f2923cd7f0d6afa7e393897d92afa6e14072655d11c4d0"
        ),
    ]
)
