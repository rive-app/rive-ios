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

    // MARK: - File Assets

    @MainActor
    func test_getAssets_returnsNativeAssetMetadata() async throws {
        let worker = try await Worker()
        let file = try await File(
            source: .local("asset_load_check", Bundle(for: Self.self)),
            worker: worker
        )

        let assets = try await file.getAssets()

        XCTAssertFalse(assets.isEmpty)
        XCTAssertTrue(assets.contains { $0.type == .image })
        XCTAssertTrue(assets.contains { $0.type == .font })
        for asset in assets {
            let nameWithoutExtension = (asset.name as NSString).deletingPathExtension
            XCTAssertEqual(asset.uniqueName, "\(nameWithoutExtension)-\(asset.assetID)")
        }

        let hostedAssets = assets.compactMap(\.cdn)
        XCTAssertFalse(hostedAssets.isEmpty)
        XCTAssertTrue(assets.contains { $0.cdn == nil })
        for cdn in hostedAssets {
            XCTAssertFalse(cdn.baseURL.isEmpty)
            XCTAssertNotNil(UUID(uuidString: cdn.uuid))
        }
    }

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

    // MARK: - Deferred Decoding
    //
    // Fixture: multipleartboards.riv defines "artboard1" and "artboard2", each with a state
    // machine named "<artboard>stateMachine1". With deferred decoding, the default artboard still
    // decodes at import, while other eligible artboards decode when first instantiated. These
    // tests check that deferred results match eager ones; the malformed-file tests below are the
    // ones that prove the policy reaches the C++ runtime.

    @MainActor
    func test_getArtboardNames_withDeferredDecoding_matchesEagerDecoding() async throws {
        let worker = try await Worker()
        let source = Source.local("multipleartboards", Bundle(for: Self.self))
        let eagerFile = try await File(source: source, worker: worker)
        let deferredFile = try await File(
            source: source,
            worker: worker,
            configuration: .init(deferDecoding: true)
        )

        let eagerNames = try await eagerFile.getArtboardNames()
        let deferredNames = try await deferredFile.getArtboardNames()

        XCTAssertEqual(deferredNames, eagerNames)
    }

    @MainActor
    func test_createStateMachine_withDeferredDecoding_createsEachArtboardAndStateMachine() async throws {
        let worker = try await Worker()
        let file = try await File(
            source: .local("multipleartboards", Bundle(for: Self.self)),
            worker: worker,
            configuration: .init(deferDecoding: true)
        )

        for name in ["artboard1", "artboard2"] {
            let artboard = try await file.createArtboard(name)
            _ = try await artboard.createStateMachine("\(name)stateMachine1")
        }
    }

    @MainActor
    func test_createViewModelInstance_withDeferredDecoding_decodesNamedInstance() async throws {
        let worker = try await Worker()
        let file = try await File(
            source: .local("data_binding_test", Bundle(for: Self.self)),
            worker: worker,
            configuration: .init(deferDecoding: true)
        )

        let instance = try await file.createViewModelInstance(.name("Editor Defaults", from: .name("Test")))
        let viewModelName = try await instance.viewModelName()
        let name = try await instance.name()

        XCTAssertEqual(viewModelName, "Test")
        XCTAssertEqual(name, "Editor Defaults")
    }

    // Fixture: malformed_deferred_artboard.riv holds the bytes of `meshWithoutIndices()` in
    // packages/runtime/tests/unit_tests/runtime/malformed_deferred_artboard.hpp. Its default
    // artboard "first" nests "second", whose mesh has no triangle indices. An eager load fails
    // the whole file. A deferred load succeeds, "first" loads with its nested artboard empty, and
    // creating "second" throws. The load outcomes differ only if the decoding policy reaches the
    // C++ runtime.

    @MainActor
    func test_init_withMalformedDeferredArtboard_andEagerDecoding_throwsInvalidFile() async throws {
        let worker = try await Worker()

        do {
            _ = try await File(
                source: .local("malformed_deferred_artboard", Bundle(for: Self.self)),
                worker: worker
            )
            XCTFail("Expected FileError.invalidFile to be thrown")
        } catch let error as FileError {
            guard case .invalidFile = error else {
                XCTFail("Expected FileError.invalidFile, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FileError, got \(type(of: error)): \(error)")
        }
    }

    @MainActor
    func test_init_withMalformedDeferredArtboard_andDeferredDecoding_loadsNestingArtboard() async throws {
        let worker = try await Worker()
        let file = try await File(
            source: .local("malformed_deferred_artboard", Bundle(for: Self.self)),
            worker: worker,
            configuration: .init(deferDecoding: true)
        )

        let names = try await file.getArtboardNames()
        _ = try await file.createArtboard("first")

        XCTAssertEqual(names, ["first", "second"])
    }

    @MainActor
    func test_createArtboard_withMalformedDeferredArtboard_throwsInvalidArtboard() async throws {
        let worker = try await Worker()
        let file = try await File(
            source: .local("malformed_deferred_artboard", Bundle(for: Self.self)),
            worker: worker,
            configuration: .init(deferDecoding: true)
        )

        do {
            _ = try await file.createArtboard("second")
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

    // MARK: - View Model Instance Names
    //
    // Fixture: data_binding_test.riv defines a view model "Test" with instances "Default" and
    // "Editor Defaults", and "Test" is the default artboard's view model.

    @MainActor
    func test_viewModelInstanceName_namedInstance_reportsRequestedName() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("data_binding_test", Bundle(for: Self.self)), worker: worker)

        let instance = try await file.createViewModelInstance(.name("Editor Defaults", from: .name("Test")))
        let viewModelName = try await instance.viewModelName()
        let name = try await instance.name()

        XCTAssertEqual(viewModelName, "Test")
        XCTAssertEqual(name, "Editor Defaults")
    }

    @MainActor
    func test_viewModelInstanceName_blankInstance_reportsEmptyName() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("data_binding_test", Bundle(for: Self.self)), worker: worker)

        let instance = try await file.createViewModelInstance(.blank(from: .name("Test")))
        let viewModelName = try await instance.viewModelName()
        let name = try await instance.name()

        XCTAssertEqual(viewModelName, "Test")
        XCTAssertEqual(name, "")
    }

    @MainActor
    func test_viewModelInstanceName_defaultInstance_reportsDefaultName() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("data_binding_test", Bundle(for: Self.self)), worker: worker)

        let instance = try await file.createViewModelInstance(.viewModelDefault(from: .name("Test")))
        let viewModelName = try await instance.viewModelName()
        let name = try await instance.name()

        XCTAssertEqual(viewModelName, "Test")
        XCTAssertEqual(name, "Default")
    }

    @MainActor
    func test_viewModelInstanceName_artboardDefaultInstance_matchesDefaultInfo() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("data_binding_test", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()
        let info = try await file.getDefaultViewModelInfo(for: artboard)

        let instance = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
        let viewModelName = try await instance.viewModelName()
        let name = try await instance.name()

        XCTAssertEqual(viewModelName, info.viewModelName)
        XCTAssertEqual(name, info.instanceName)
    }

    @MainActor
    func test_getDefaultViewModelInfo_withNoViewModel_throwsInvalidArtboard() async throws {
        let worker = try await Worker()
        let file = try await File(source: .local("no_view_model", Bundle(for: Self.self)), worker: worker)
        let artboard = try await file.createArtboard()

        do {
            _ = try await file.getDefaultViewModelInfo(for: artboard)
            XCTFail("Expected ArtboardError.invalidArtboard to be thrown")
        } catch let error as ArtboardError {
            guard case .invalidArtboard(let message) = error else {
                XCTFail("Expected ArtboardError.invalidArtboard, got \(error)")
                return
            }
            XCTAssertEqual(
                message,
                "Could not find default view model for artboard when getting default view model info"
            )
        } catch {
            XCTFail("Expected ArtboardError, got \(type(of: error)): \(error)")
        }
    }
}
