import Foundation

public enum StateMachineError: LocalizedError {
    case error(String)
    case cancelled
    case duplicateGlobalViewModelInstance(String)
    case invalidGlobalViewModelName(String)

    public var errorDescription: String? {
        switch self {
        case .error(let message):
            return message
        case .cancelled:
            return "Operation was cancelled."
        case .invalidGlobalViewModelName(let name):
            return "No global view model named '\(name)' is defined in the source file."
        case .duplicateGlobalViewModelInstance(let name):
            return "Only one global view model instance named '\(name)' can be bound."
        }
    }
}
