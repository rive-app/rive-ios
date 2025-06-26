// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "RiveRuntime",
	platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1"), .macCatalyst("14.0")],
	products: [
		.library(
			name: "RiveRuntime",
			targets: ["RiveRuntime"]
		),
		.plugin(name: "RivePlugin", targets: ["RivePlugin"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
	],
	targets: [
		.binaryTarget(
			name: "RiveRuntime",
			url: "https://github.com/rive-app/rive-ios/releases/download/6.9.4/RiveRuntime.xcframework.zip",
			checksum: "e5a5c810a838cf1ac8e44dcff606f84c1dbb80b17a144f6d7099b57705d83ee9"
		),
		.executableTarget(
			name: "rive-codegen",
			dependencies: [
				.target(name: "RiveRuntime"),
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			linkerSettings: [
				.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"]),
			]
		),
		.plugin(
			name: "RivePlugin",
			capability: .buildTool(),
			dependencies: ["rive-codegen"],
			path: "Plugin"
		),
	]
)
