import Foundation
import RiveRuntime

struct RiveDocument {
	struct Artboard {
		let name: String
		let isDefault: Bool
		let defaultViewModel: String?
	}

	struct ViewModel {
		struct Property {
			enum PropertyType {
				case none
				case string
				case number
				case boolean
				case color
				case list
				case `enum`(String)
				case trigger
				case viewModel(String)
				case integer
				case symbolListIndex
				case assetImage
			}

			let name: String
			let type: PropertyType
		}

		let name: String
		let properties: [Property]
	}

	struct Enum {
		let name: String
		let values: [String]
	}

	let path: URL
	let name: String
	let enums: [Enum]
	let artboards: [Artboard]
	let viewModels: [ViewModel]
}

actor Generator: Sendable {
	let isDryRun: Bool
	var documents: [RiveDocument] = []

	init(isDryRun: Bool = false) {
		self.isDryRun = isDryRun
	}

	func load(_ url: URL) async throws {
		let riveFile = try RiveRuntime.RiveFile(data: Data(contentsOf: url), loadCdn: false)

		let defaultArtboard = try riveFile.artboard()
		let artboards = try riveFile.artboardNames().map { try riveFile.artboard(fromName: $0) }.map { artboard in
			RiveDocument.Artboard(
				name: artboard.name(),
				isDefault: artboard.name() == defaultArtboard.name(),
				defaultViewModel: riveFile.defaultViewModel(for: artboard).map { $0.name }
			)
		}

		var enums: [RiveDocument.Enum] = []

		let riveViewModels = Array(0..<riveFile.viewModelCount).compactMap { riveFile.viewModel(at: $0) }

		let viewModels = riveViewModels.compactMap { viewModel -> RiveDocument.ViewModel? in
			guard let instance = viewModel.createDefaultInstance() ?? viewModel.createInstance() else { return nil }

			let createEnum = { (propertyName: String) -> String in
				let enumInstance = instance.enumProperty(fromPath: propertyName)!
				// TODO: Find a way to extract the real enum name from the Rive file
				let name = "Enum\(enums.count + 1)"

				enums.append(
					RiveDocument.Enum(name: name, values: enumInstance.values)
				)

				return name
			}

			let findViewModelName = { (propertyName: String) -> String in
				let viewModelInstance = instance.viewModelInstanceProperty(fromPath: propertyName)!

				// TODO: Find a better way to match view models
				return riveViewModels.first(where: { $0.properties.map { $0.name } == viewModelInstance.properties.map { $0.name } })?.name ?? "UnknownViewModel"
			}

			let properties = viewModel.properties.map { property in
				let type: RiveDocument.ViewModel.Property.PropertyType = switch property.type {
					case .none: .none
					case .string: .string
					case .number: .number
					case .boolean: .boolean
					case .color: .color
					case .list: .list
					case .trigger: .trigger
					case .integer: .integer
					case .assetImage: .assetImage
					case .symbolListIndex: .symbolListIndex
					case .enum: .enum(createEnum(property.name))
					case .viewModel: .viewModel(findViewModelName(property.name))
					@unknown default: fatalError("Unknown property type: \(property.type)")
				}

				return RiveDocument.ViewModel.Property(name: property.name, type: type)
			}

			return RiveDocument.ViewModel(name: viewModel.name, properties: properties)
		}

		documents.append(
			RiveDocument(
				path: url,
				name: url.lastPathComponent.withoutExtension().pascalCased(),
				enums: enums,
				artboards: artboards,
				viewModels: viewModels
			)
		)
	}

	func generate(outputDirectory: URL, as fileName: String) async throws {
		let data = """
		// Auto-generated file. Do not edit manually.
		// swiftlint:disable all

		import Foundation
		import RiveRuntime

		#if os(macOS)
		import AppKit
		typealias RiveColor = NSColor
		#else
		import UIKit
		typealias RiveColor = UIColor
		#endif

		enum Rive {
			\(documents.map { generate(for: $0) }.joined(separator: "\n\n\t\t"))
		}
		""".data(using: .utf8)!

		let fileManager = FileManager.default
		let destinationURL = outputDirectory.appendingPathComponent(fileName)

		if !isDryRun, let existingData = try? Data(contentsOf: destinationURL), existingData == data {
			print("File \(destinationURL.lastPathComponent) already up to date.")
			return
		}

		if isDryRun {
			print("Dry run enabled. Would write data to \(destinationURL.lastPathComponent).")
			print(String(data: data, encoding: .utf8)!)

		} else {
			print("Writing data to file \(destinationURL.lastPathComponent)...")

			try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
			try data.write(to: destinationURL)
		}
	}

	private func generate(for document: RiveDocument) -> String {
		var declaration = "final class \(document.name.pascalCased()): RiveViewModel {\n"

		for riveEnum in document.enums {
			declaration += """
			\t\tenum \(riveEnum.name.pascalCased()): String, CaseIterable {
			\(riveEnum.values.map { "\t\t\tcase `\($0)` = \"\($0)\"" }.joined(separator: "\n"))
			\t\t}\n\n
			"""
		}

		for viewModel in document.viewModels {
			declaration += """
			\t\tstruct \(viewModel.name.pascalCased()) {
			\t\t\t\(viewModel.properties.map { generate(for: $0) }.joined(separator: "\n\t\t\t"))
			\t\t}\n\n
			"""
		}

		declaration += "\n\t}"
		return declaration
	}

	private func generate(for property: RiveDocument.ViewModel.Property) -> String {
		let type = switch property.type {
			case .none: "Any"
			case .list: "[Any]" // TODO: What type are lists?
			case .integer: "Int"
			case .string: "String"
			case .number: "Double"
			case .boolean: "Bool"
			case .color: "RiveColor"
			case let .enum(name): name
			case let .viewModel(name): name
			case .symbolListIndex: "Int" // TODO: What type is this?
			case .assetImage: "RiveRenderImage"
			case .trigger: "RiveDataBindingViewModel.Instance.TriggerProperty"
		}

		return "var `\(property.name)`: \(type)"
	}
}
