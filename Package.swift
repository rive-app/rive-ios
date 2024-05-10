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
            url: "https://github.com/rive-app/rive-ios/releases/download/5.11.3/RiveRuntime.xcframework.zip",
            checksum: "ef3144be6a36ad5a854ecb9db8106c43226e101506a03ced2d1634696dea761f"
        ),
    ]
)
