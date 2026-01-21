//
//  FileLoaderTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 5/27/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class FileLoaderTests: XCTestCase {
    @MainActor
    func test_localSource_ifExists_returnsFile() async throws {
        let loader = FileLoader(
            source: .local("defaultstatemachine", Bundle(for: Self.self)),
            dependencies: .init(
                urlSession: URLSession.shared
            )
        )

        let data = try await loader.load()
        XCTAssertFalse(data.isEmpty)
    }

    @MainActor
    func test_localSource_ifNotExists_throwsError() async {
        let loader = FileLoader(
            source: .local("404", Bundle(for: Self.self)),
            dependencies: .init(
                urlSession: MockURLSession()
            )
        )

        do {
            _ = try await loader.load()
            XCTFail("load() should have thrown")
        } catch let error as FileError {
            if case .missingFile(let message) = error {
                XCTAssertEqual(message, "404")
            } else {
                XCTFail("Expected FileError.missingFile(\"404\"), got \(error)")
            }
        } catch {
            XCTFail("Expected FileError.missingFile, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_urlSource_ifExists_returnsFile() async throws {
        let urlSession = MockURLSession()
        let loader = FileLoader(
            source: .url(URL(string: "https://rive.app")!),
            dependencies: .init(
                urlSession: urlSession
            )
        )

        urlSession.stubGet { _, completionHandler in
            let data = Data([UInt8(1)])
            completionHandler(data, nil, nil)
        }

        let data = try await loader.load()
        XCTAssertFalse(data.isEmpty)
    }

    @MainActor
    func test_urlSource_ifExists_withEmptyData_throwsError() async {
        let urlSession = MockURLSession()
        let loader = FileLoader(
            source: .url(URL(string: "https://rive.app")!),
            dependencies: .init(
                urlSession: urlSession
            )
        )

        urlSession.stubGet { _, completionHandler in
            completionHandler(Data(), nil, nil)
        }

        do {
            _ = try await loader.load()
            XCTFail("load() should have thrown")
        } catch let error as FileError {
            if case .missingData(let urlString) = error {
                XCTAssertEqual(urlString, "https://rive.app")
            } else {
                XCTFail("Expected FileError.missingData(\"https://rive.app\"), got \(error)")
            }
        } catch {
            XCTFail("Expected FileError.missingData, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_urlSource_ifNotExists_withError_returnsNil() async {
        struct _Error: Error { }

        let urlSession = MockURLSession()
        let loader = FileLoader(
            source: .url(URL(string: "https://rive.app")!),
            dependencies: .init(
                urlSession: urlSession
            )
        )

        urlSession.stubGet { _, completionHandler in
            completionHandler(nil, nil, _Error())
        }

        do {
            _ = try await loader.load()
            XCTFail("load() should have thrown")
        } catch let error as FileError {
            if case .missingData(let urlString) = error {
                XCTAssertEqual(urlString, "https://rive.app")
            } else {
                XCTFail("Expected FileError.missingData(\"https://rive.app\"), got \(error)")
            }
        } catch {
            XCTFail("Expected FileError.missingData, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_dataSource_returnsData() async throws {
        let bytes: [UInt8] = [0x0, 0x1, 0x2, 0x3]
        let data = Data(bytes: bytes, count: bytes.count)
        let loader = FileLoader(source: .data(data))
        let loaded = try await loader.load()
        XCTAssertEqual(loaded, data)
    }

    @MainActor
    func test_localSource_withUnreadableFile_throwsInvalidFileError() async {
        // Use a directory URL which will cause Data(contentsOf:) to throw an error
        // when trying to read it as data
        let tempDirURL = FileManager.default.temporaryDirectory
        
        let mockBundle = MockBundle()
        mockBundle.stubUrlForResource { name, ext in
            // Return the directory URL if the filename matches
            if name == "test_unreadable" && ext == "riv" {
                return tempDirURL
            }
            return nil
        }
        
        let loader = FileLoader(
            source: .local("test_unreadable", mockBundle),
            dependencies: .init(
                urlSession: MockURLSession()
            )
        )
        
        do {
            _ = try await loader.load()
            XCTFail("load() should have thrown")
        } catch let error as FileError {
            if case .invalidFile(let urlString) = error {
                // Verify the error contains the URL (it should be the directory URL we provided)
                XCTAssertTrue(urlString == tempDirURL.absoluteString || urlString.contains("test_unreadable"))
            } else {
                XCTFail("Expected FileError.invalidFile, got \(error)")
            }
        } catch {
            XCTFail("Expected FileError.invalidFile, got \(type(of: error)): \(error)")
        }
    }
}
