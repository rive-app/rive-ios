import Foundation
import PackagePlugin

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
	case incompatibleTarget(name: String)

	var description: String {
		switch self {
			case let .incompatibleTarget(name): "Incompatible target called '\(name)'. Only Swift source targets can be used with the Rive plugin."
		}
	}

	var errorDescription: String? { description }
}

@main
struct RivePlugin {
	func createBuildCommands(
		pluginWorkDirectory: URL,
		tool: (String) throws -> PluginContext.Tool,
		sourceFiles: FileList
	) throws -> [Command] {
		let outputDir = pluginWorkDirectory.appending(path: "GeneratedSources")
		let inputFiles = sourceFiles.filter { $0.url.lastPathComponent.hasSuffix(".riv") }.map(\.url)

		return try [
			.buildCommand(
				displayName: "Running rive-codegen",
				executable: tool("rive-codegen").url,
				arguments: ["generate"] + inputFiles.map { $0.absoluteString } + ["--output-directory", "\(outputDir)"],
				environment: [:],
				inputFiles: inputFiles,
				outputFiles: [outputDir.appending(path: "Rive+Generated.swift")]
			),
		]
	}
}

extension RivePlugin: BuildToolPlugin {
	func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
		guard let swiftTarget = target as? SwiftSourceModuleTarget else {
			throw PluginError.incompatibleTarget(name: target.name)
		}

		return try createBuildCommands(pluginWorkDirectory: context.pluginWorkDirectoryURL, tool: context.tool, sourceFiles: swiftTarget.sourceFiles)
	}
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension RivePlugin: XcodeBuildToolPlugin {
	func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
		try createBuildCommands(pluginWorkDirectory: context.pluginWorkDirectoryURL, tool: context.tool, sourceFiles: target.inputFiles)
	}
}
#endif
