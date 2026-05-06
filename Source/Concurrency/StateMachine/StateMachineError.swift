import Foundation

public enum StateMachineError: LocalizedError {
    case error(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .error(let message):
            return message
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
