// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/6.5.5/RiveRuntime.xcframework.zip",
            checksum: "6b0d50ee31ab38e6887b0dae8ef7ade5cc43e021d5f8368c95e05f6e3651d31a"
        ),
        .target(
            name: "RiveRuntime-Resources",
            path: "Resources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)
