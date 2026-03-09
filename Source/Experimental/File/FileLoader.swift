//
//  RiveUIFileLoader.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// Represents the source location of a Rive file that can be loaded.
///
/// Sources can be either local files stored in app bundles or remote files accessible via URL.
@_spi(RiveExperimental)
public enum Source: Sendable {
    /// A local Rive file stored within an app bundle.
    ///
    /// - Parameters:
    ///   - filename: The name of the Rive file without the `.riv` extension
    ///   - bundle: The bundle containing the file. If `nil`, defaults to `Bundle.main`
    case local(String, Bundle?)
    
    /// A remote Rive file accessible via URL.
    ///
    /// - Parameter url: The URL pointing to the Rive file to download
    case url(URL)

    /// Data that has already been loaded.
    ///
    /// - Parameter data: The data has already been loaded.
    case data(Data)
}

/// The interface for an object capable of loading Rive files.
///
/// This protocol does not interact with the command queue; it only loads raw file data.
/// The loaded data is then passed to `FileService` which handles command queue interactions.
protocol FileLoaderProtocol: AnyObject, Sendable {
    /// Loads a Rive file and returns a file handle for further operations.
    ///
    /// This method performs the actual loading of the Rive file based on the source
    /// specified during initialization. The loading process is asynchronous and may
    /// involve network requests for remote files or file system access for local files.
    ///
    /// - Returns: A `File.FileHandle` that can be used to access the loaded file
    /// - Throws: `FileError.missingFile` if the local file cannot be found
    ///           `FileError.missingData` if the remote file cannot be downloaded
    ///           `FileError.invalidFile` or `FileError.invalidData` for other loading failures
    func load() async throws -> Data
}

/// A concrete implementation of `FileLoaderProtocol` that handles loading Rive files
/// from both local and remote sources.
///
/// Does not interact with the command queue; only handles data retrieval. The loaded data
/// is passed to `FileService` for command queue-based parsing.
final class FileLoader: FileLoaderProtocol {
    /// The source of the Rive file to be loaded
    private let source: Source
    
    /// Dependencies required for file loading operations
    private let dependencies: Dependencies

    /// Convenience initializer that creates a loader with default dependencies.
    ///
    /// - Parameter source: The source of the Rive file to load
    @MainActor
    convenience init(source: Source) {
        self.init(
            source: source,
            dependencies: Dependencies(
                urlSession: URLSession.shared
            )
        )
    }

    /// Designated initializer that allows for custom dependencies.
    ///
    /// - Parameters:
    ///   - source: The source of the Rive file to load
    ///   - dependencies: Custom dependencies for file loading operations
    @MainActor
    init(source: Source, dependencies: Dependencies) {
        self.source = source
        self.dependencies = dependencies
    }

    /// Loads a Rive file based on the specified source.
    ///
    /// - Returns: The loaded file data
    /// - Throws: Various `FileError` cases depending on the failure reason
    @MainActor
    func load() async throws -> Data {
        switch source {
        case .local(let filename, let bundle):
            return try await load(filename: filename, in: bundle)
        case .url(let url):
            return try await load(url: url)
        case .data(let data):
            return data
        }
    }

    /// Loads a local Rive file from the specified bundle.
    ///
    /// - Parameters:
    ///   - filename: The name of the Rive file without the `.riv` extension
    ///   - bundle: The bundle containing the file. If `nil`, defaults to `Bundle.main`
    /// - Returns: The loaded file data
    /// - Throws: `FileError.missingFile` if the file cannot be found in the bundle
    ///           `FileError.invalidFile` if the file cannot be loaded
    private func load(filename: String, in bundle: Bundle?) async throws -> Data {
        return try await Task.detached(priority: .userInitiated) {
            let bundle = bundle ?? Bundle.main
            guard let url = bundle.url(forResource: filename, withExtension: "riv") else {
                throw FileError.missingFile(filename)
            }

            do {
                let data = try Data(contentsOf: url)
                return data
            } catch {
                throw FileError.invalidFile(url.absoluteString)
            }
        }.value
    }

    /// Loads a remote Rive file from the specified URL.
    ///
    /// Uses continuations to bridge the callback-based URL session API to async/await.
    /// Continuations are resumed on the main actor, consistent with command queue main thread requirements.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the Rive file
    /// - Returns: The downloaded file data
    /// - Throws: `FileError.missingData` if the download fails or returns empty data
    private func load(url: URL) async throws -> Data {
        let urlSession = dependencies.urlSession
        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.get(url: url) { data, response, error in
                guard error == nil, let data, data.isEmpty == false else {
                    Task { @MainActor in
                        continuation.resume(throwing: FileError.missingData(url.absoluteString))
                    }
                    return
                }

                Task { @MainActor in
                    continuation.resume(returning: data)
                }
            }
            task.resume()
        }
    }
}

extension FileLoader {
    /// Dependencies required by the FileLoader for file loading operations.
    ///
    /// Protocol-based design allows for dependency injection and testing.
    /// Does not include command queue dependencies; only handles data retrieval.
    struct Dependencies: Sendable {
        /// The URL session used for downloading remote files.
        let urlSession: URLSessionProtocol
    }
}

/// Protocol defining the interface for URL session operations.
///
/// Enables dependency injection and testing. The completion handler is called on an
/// arbitrary background queue, so callers must dispatch to the appropriate actor.
protocol URLSessionProtocol: Sendable {
    /// Creates a data task for the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL to request data from
    ///   - completionHandler: The completion handler called when the request completes
    /// - Returns: A data task that can be resumed to start the request
    func get(url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTaskProtocol
}

/// Protocol defining the interface for URL session data tasks.
///
/// Enables dependency injection and testing. Only exposes `resume()` to start network requests.
protocol URLSessionDataTaskProtocol {
    /// Starts the data task to begin the network request.
    func resume()
}

extension URLSession: URLSessionProtocol {
    func get(url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> any URLSessionDataTaskProtocol {
        return self.dataTask(with: url, completionHandler: completionHandler)
    }
}

/// Extension that makes `URLSessionDataTask` conform to `URLSessionDataTaskProtocol`.
extension URLSessionDataTask: URLSessionDataTaskProtocol { }
