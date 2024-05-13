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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.11.4/RiveRuntime.xcframework.zip",
            checksum: "b0fc7c799f2fe4cda9de5014548695b77c6dbbe1b6545671d78c16a94b8605b5"
        ),
        .target(
            name: "RiveRuntime",
            path: "Resources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)

