// swift-tools-version:5.9
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
            url: "https://github.com/rive-app/rive-ios/releases/download/6.3.6/RiveRuntime.xcframework.zip",
            checksum: "a98295b5817d65d1bdacc349f17fd12cf7bed2ba8715f769a130da65107a64f2"
        ),
        .target(
            name: "RiveRuntime-Resources",
            path: "Resources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)
