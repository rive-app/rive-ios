// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1"), .macCatalyst("14.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.23.0/RiveRuntime.xcframework.zip",
            checksum: "48a0ab76c3d614c621b44d492d81c7cd1993d868f95ee5305e0a217c8fefedb7"
        )
    ]
)
