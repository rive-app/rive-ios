import Foundation
import ArgumentParser

extension URL: @retroactive ExpressibleByArgument {
	public init?(argument: String) {
		self.init(string: argument)
	}
}

extension String {
	func withoutExtension() -> String {
		split(separator: ".").dropLast().joined(separator: ".")
	}

	func pascalCased() -> String {
		components(separatedBy: CharacterSet(charactersIn: "-_")).map { $0.capitalized }.joined()
	}
}
