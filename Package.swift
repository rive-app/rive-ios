// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("11.0")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/rive-app/rive-ios/releases/download/1.0.14/RiveRuntime.xcframework.zip",
            checksum: "cbc3fbd03dcf1ae2f4a1327f1ca5017fbdfbc2ab181368a4ef97765bf625d0b3"
        ),
    ]
)
