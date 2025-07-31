// swift-tools-version:5.9
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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.11.1/RiveRuntime.xcframework.zip",
            checksum: "c84b03955242ae56767246afd7287df9660a459035b71607344e87ad5baa2516"
        )
    ]
)
