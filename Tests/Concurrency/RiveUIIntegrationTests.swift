//
//  RiveUIIntegrationTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 8/6/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
import RiveRuntime

class RiveUIIntegrationTests: XCTestCase {

    // MARK: - Artboard

    @MainActor
    func test_createArtboard_withNoArtboard_throwsInvalidArtboard() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("empty", Bundle(for: Self.self)), worker: worker)

        do {
            _ = try await file.createArtboard()
            XCTFail("Expected FileError.invalidArtboard to be thrown")
        } catch let error as FileError {
            guard case .invalidArtboard = error else {
                XCTFail("Expected FileError.invalidArtboard, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createArtboard_withInvalidName_throwsInvalidArtboard() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_state_machine", Bundle(for: Self.self)), worker: worker)

        do {
            _ = try await file.createArtboard("Nonexistent")
            XCTFail("Expected FileError.invalidArtboard to be thrown")
        } catch let error as FileError {
            guard case .invalidArtboard = error else {
                XCTFail("Expected FileError.invalidArtboard, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - State Machine

    @MainActor
    func test_createStateMachine_withNoStateMachine_throwsInvalidStateMachine() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_state_machine", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await artboard.createStateMachine()
            XCTFail("Expected ArtboardError.invalidStateMachine to be thrown")
        } catch let error as ArtboardError {
            guard case .invalidStateMachine = error else {
                XCTFail("Expected ArtboardError.invalidStateMachine, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected ArtboardError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createStateMachine_withInvalidName_throwsInvalidStateMachine() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_state_machine", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await artboard.createStateMachine("Nonexistent")
            XCTFail("Expected ArtboardError.invalidStateMachine to be thrown")
        } catch let error as ArtboardError {
            guard case .invalidStateMachine = error else {
                XCTFail("Expected ArtboardError.invalidStateMachine, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected ArtboardError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - View Model Instance

    @MainActor
    func test_createBlankViewModelInstanceForArtboard_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await file.createViewModelInstance(.blank(from: .artboardDefault(artboard)))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createBlankViewModelInstanceNamed_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)

        do {
            _ = try await file.createViewModelInstance(.blank(from: .name("Nonexistent")))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createDefaultViewModelInstanceForArtboard_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createDefaultViewModelInstanceNamed_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)

        do {
            _ = try await file.createViewModelInstance(.viewModelDefault(from: .name("Nonexistent")))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createNamedViewModelInstanceForArtboard_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await file.createViewModelInstance(.name("Nonexistent", from: .artboardDefault(artboard)))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_createNamedViewModelInstanceNamed_withNoViewModel_throwsInvalidViewModelInstance() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)

        do {
            _ = try await file.createViewModelInstance(.name("Nonexistent", from: .name("Nonexistent")))
            XCTFail("Expected FileError.invalidViewModelInstance to be thrown")
        } catch let error as FileError {
            guard case .invalidViewModelInstance = error else {
                XCTFail("Expected FileError.invalidViewModelInstance, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }
}
