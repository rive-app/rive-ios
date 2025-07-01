import Foundation
import ArgumentParser

@main struct Command: AsyncParsableCommand {
	static let configuration: CommandConfiguration = .init(
		commandName: "rive-codegen",
		abstract: "Generate Swift code for your Rive files",
		subcommands: [GenerateCommand.self]
	)
}

struct GenerateCommand: AsyncParsableCommand {
	struct Options: ParsableArguments {
		@Argument(help: "A list of Rive files to generate code for")
		var inputFiles: [URL]
	}

	static let configuration: CommandConfiguration = .init(
		commandName: "generate",
		abstract: "Generate Swift code for your Rive files",
	)

	@OptionGroup var options: Options

	@Option(
		help:
		"Output directory where the generated files are written. Warning: Replaces any existing files with the same filename."
	) var outputDirectory: URL = .init(fileURLWithPath: FileManager.default.currentDirectoryPath)

	@Flag(
		name: .customLong("dry-run"),
		help: "Simulate the command and print the operations, without actually affecting the file system."
	) var isDryRun: Bool = false

	func run() async throws {
		let files = options.inputFiles

		print(
			"""
			Swift Rive Code Generator is running with the following configuration:
			- input files: \(files)
			- Is dry run: \(isDryRun)
			- Output directory: \(outputDirectory.path)
			- Current directory: \(FileManager.default.currentDirectoryPath)
			"""
		)

		let generator = Generator(isDryRun: isDryRun)

		try await withThrowingTaskGroup(of: Void.self) { group in
			for file in files {
				group.addTask {
					try await generator.load(file)
				}
			}

			try await group.waitForAll()
		}

		try await generator.generate(outputDirectory: outputDirectory, as: "Rive+Generated.swift")
	}
}
