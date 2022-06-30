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
            url: "https://github.com/rive-app/rive-ios/releases/download/2.0.29/RiveRuntime.xcframework.zip",
            checksum: "fa2cfa54bcf01b89a6948380c89520ca5cab30692011aecbdda4a8542da018e4"
        ),
    ]
)
