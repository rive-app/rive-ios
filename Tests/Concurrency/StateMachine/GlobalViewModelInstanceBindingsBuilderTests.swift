//
//  GlobalViewModelInstanceBindingsBuilderTests.swift
//  RiveRuntimeTests
//
//  Created by Rive on 7/29/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import XCTest
import Combine
@preconcurrency @testable import RiveRuntime

class GlobalViewModelInstanceBindingsBuilderTests: XCTestCase {
    @MainActor
    private func makeStateMachine(
        handle: StateMachine.StateMachineHandle = 123,
        commandQueue: MockCommandQueue
    ) -> StateMachine {
        let service = StateMachineService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: service),
            stateMachineHandle: handle
        )
        let fileService = stateMachine.sourceArtboard.sourceFile.dependencies.fileService
        commandQueue.stubRequestGlobalViewModelNames { handle, requestID in
            fileService.onGlobalViewModelsListed(handle, requestID: requestID, names: ["Theme", "Localization", "Global 0", "Global 1"])
        }
        return stateMachine
    }

    @MainActor
    private func makeViewModelInstance(
        handle: ViewModelInstance.ViewModelInstanceHandle,
        commandQueue: MockCommandQueue
    ) -> ViewModelInstance {
        let service = ViewModelInstanceService(
            dependencies: .init(
                commandQueue: commandQueue,
                messageGate: CommandQueueMessageGate(driver: commandQueue)
            )
        )
        return ViewModelInstance(
            handle: handle,
            dependencies: .init(viewModelInstanceService: service)
        )
    }

    @MainActor
    func test_bindViewModelInstances_stagesBindingsAndBinds() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let main = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let theme = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        let localization = makeViewModelInstance(handle: 3, commandQueue: mockCommandQueue)

        try await stateMachine.bindViewModelInstances(main: main) {
            ("Theme", theme)
            ("Localization", localization)
        }

        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.stateMachineHandle, 123)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 2)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[0].name, "Theme")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[0].viewModelInstanceHandle, 2)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[1].name, "Localization")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[1].viewModelInstanceHandle, 3)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.bindCalls.first?.stateMachineHandle, 123)
        XCTAssertTrue(stateMachine.mainBinding === main)
        XCTAssertTrue(stateMachine.globalBindings["Theme"] === theme)
        XCTAssertTrue(stateMachine.globalBindings["Localization"] === localization)
    }

    @MainActor
    func test_bindViewModelInstances_supportsOptionalBindings() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let theme = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let localization = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        let includeTheme = false

        try await stateMachine.bindViewModelInstances {
            if includeTheme {
                ("Theme", theme)
            }
            ("Localization", localization)
        }

        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.name, "Localization")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.viewModelInstanceHandle, 2)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertNil(stateMachine.mainBinding)
    }

    @MainActor
    func test_bindViewModelInstances_supportsEitherBindings() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let lightTheme = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let darkTheme = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        let useDarkTheme = true

        try await stateMachine.bindViewModelInstances {
            if useDarkTheme {
                ("Theme", darkTheme)
            } else {
                ("Theme", lightTheme)
            }
        }

        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.name, "Theme")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.first?.viewModelInstanceHandle, 2)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
    }

    @MainActor
    func test_bindViewModelInstances_supportsArrays() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let instances = [
            makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue),
            makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue),
        ]

        try await stateMachine.bindViewModelInstances {
            for (index, instance) in instances.enumerated() {
                ("Global \(index)", instance)
            }
        }

        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 2)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[0].name, "Global 0")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[0].viewModelInstanceHandle, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[1].name, "Global 1")
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls[1].viewModelInstanceHandle, 2)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
    }

    @MainActor
    func test_bindViewModelInstances_withoutMain_preservesExistingMain() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let main = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let lightTheme = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        let darkTheme = makeViewModelInstance(handle: 3, commandQueue: mockCommandQueue)

        try await stateMachine.bindViewModelInstances(main: main) {
            ("Theme", lightTheme)
        }
        try await stateMachine.bindViewModelInstances {
            ("Theme", darkTheme)
        }

        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceCalls.first?.viewModelInstanceHandle, 1)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.count, 2)
        XCTAssertEqual(mockCommandQueue.setGlobalViewModelInstanceCalls.last?.viewModelInstanceHandle, 3)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 2)
        XCTAssertTrue(stateMachine.mainBinding === main)
    }

    @MainActor
    func test_bindViewModelInstances_retainsViewModelInstances() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        var main: ViewModelInstance? = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        var theme: ViewModelInstance? = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        let retainedMain = WeakReference(main)
        let retainedTheme = WeakReference(theme)

        try await stateMachine.bindViewModelInstances(main: main!) {
            ("Theme", theme!)
        }
        main = nil
        theme = nil

        XCTAssertNotNil(retainedMain.value)
        XCTAssertNotNil(retainedTheme.value)
        XCTAssertTrue(stateMachine.mainBinding === retainedMain.value)
        XCTAssertTrue(stateMachine.globalBindings["Theme"] === retainedTheme.value)
    }

    @MainActor
    func test_bindViewModelInstances_releasesReplacedMainViewModelInstance() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        var first: ViewModelInstance? = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let replacedMain = WeakReference(first)
        let second = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)

        try await stateMachine.bindViewModelInstances(main: first!)
        first = nil
        try await stateMachine.bindViewModelInstances(main: second)

        XCTAssertNil(replacedMain.value)
        XCTAssertTrue(stateMachine.mainBinding === second)
    }

    @MainActor
    func test_bindViewModelInstances_releasesReplacedGlobalViewModelInstance() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        var first: ViewModelInstance? = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let replacedGlobal = WeakReference(first)
        let second = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)

        try await stateMachine.bindViewModelInstances {
            ("Theme", first!)
        }
        first = nil
        try await stateMachine.bindViewModelInstances {
            ("Theme", second)
        }

        XCTAssertNil(replacedGlobal.value)
        XCTAssertTrue(stateMachine.globalBindings["Theme"] === second)
    }

    @MainActor
    func test_bindViewModelInstances_omittingGlobalPreservesExistingBinding() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let theme = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let localization = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)

        try await stateMachine.bindViewModelInstances {
            ("Theme", theme)
        }
        try await stateMachine.bindViewModelInstances {
            ("Localization", localization)
        }

        XCTAssertTrue(stateMachine.globalBindings["Theme"] === theme)
        XCTAssertTrue(stateMachine.globalBindings["Localization"] === localization)
    }

    @MainActor
    func test_bindViewModelInstances_withNoBindings_bindsWithoutSettingMain() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        var changeCount = 0
        let cancellable = stateMachine.bindingsDidChange.sink {
            changeCount += 1
        }

        try await stateMachine.bindViewModelInstances()

        XCTAssertTrue(mockCommandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.setGlobalViewModelInstanceCalls.isEmpty)
        XCTAssertEqual(mockCommandQueue.bindCalls.count, 1)
        XCTAssertNil(stateMachine.mainBinding)
        XCTAssertEqual(changeCount, 1)
        withExtendedLifetime(cancellable) {}
    }

    @MainActor
    func test_bindViewModelInstances_emitsOneChangePerCall() async throws {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let main = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let theme = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)
        var changeCount = 0
        let cancellable = stateMachine.bindingsDidChange.sink {
            changeCount += 1
        }

        try await stateMachine.bindViewModelInstances(main: main) {
            ("Theme", theme)
        }

        XCTAssertEqual(changeCount, 1)
        withExtendedLifetime(cancellable) {}
    }

    @MainActor
    func test_bindViewModelInstances_withDuplicateGlobalBindings_throwsStateMachineError() async {
        let mockCommandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: mockCommandQueue)
        let first = makeViewModelInstance(handle: 1, commandQueue: mockCommandQueue)
        let second = makeViewModelInstance(handle: 2, commandQueue: mockCommandQueue)

        do {
            try await stateMachine.bindViewModelInstances {
                ("Theme", first)
                ("Theme", second)
            }
            XCTFail("Expected duplicate name error")
        } catch {
            guard case StateMachineError.duplicateGlobalViewModelInstance = error else {
                XCTFail("Expected StateMachineError.duplicateGlobalViewModelInstance, got \(type(of: error)): \(error)")
                return
            }
        }

        XCTAssertTrue(mockCommandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.setGlobalViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.bindCalls.isEmpty)
        XCTAssertTrue(mockCommandQueue.requestGlobalViewModelNamesCalls.isEmpty)
    }
    @MainActor
    func test_invalidGlobalName_preservesAllBindingsAndDoesNotNotify() async throws {
        let commandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: commandQueue)
        let original = makeViewModelInstance(handle: 1, commandQueue: commandQueue)
        let replacement = makeViewModelInstance(handle: 2, commandQueue: commandQueue)
        try await stateMachine.bindViewModelInstances(main: original) {
            ("Theme", original)
        }
        var changes = 0
        let observation = stateMachine.bindingsDidChange.sink { changes += 1 }

        do {
            try await stateMachine.bindViewModelInstances(main: replacement) {
                ("Theme", replacement)
                ("Thmee", replacement)
            }
            XCTFail("Expected invalid global name")
        } catch StateMachineError.invalidGlobalViewModelName(let name) {
            XCTAssertEqual(name, "Thmee")
        }

        XCTAssertEqual(commandQueue.setViewModelInstanceCalls.count, 1)
        XCTAssertEqual(commandQueue.setGlobalViewModelInstanceCalls.count, 1)
        XCTAssertEqual(commandQueue.bindCalls.count, 1)
        XCTAssertTrue(stateMachine.mainBinding === original)
        XCTAssertTrue(stateMachine.globalBindings["Theme"] === original)
        XCTAssertNil(stateMachine.globalBindings["Thmee"])
        XCTAssertEqual(changes, 0)
        withExtendedLifetime(observation) {}
    }

    @MainActor
    func test_globalNames_areSharedAcrossArtboardsFromTheSameFile() async throws {
        let commandQueue = MockCommandQueue()
        let first = makeStateMachine(commandQueue: commandQueue)
        let file = first.sourceArtboard.sourceFile
        let artboard = Artboard(dependencies: first.sourceArtboard.dependencies, artboardHandle: 456, sourceFile: file)
        let service = StateMachineService(dependencies: .init(commandQueue: commandQueue, messageGate: CommandQueueMessageGate(driver: commandQueue)))
        let second = StateMachine(dependencies: .init(stateMachineService: service), stateMachineHandle: 789, sourceArtboard: artboard)
        let theme = makeViewModelInstance(handle: 1, commandQueue: commandQueue)

        for stateMachine in [first, second] {
            try await stateMachine.bindViewModelInstances {
                ("Theme", theme)
            }
        }

        XCTAssertEqual(commandQueue.requestGlobalViewModelNamesCalls.count, 1)
        XCTAssertEqual(commandQueue.requestGlobalViewModelNamesCalls.first?.fileHandle, file.fileHandle)
        XCTAssertTrue(first.globalBindings["Theme"] === theme)
        XCTAssertTrue(second.globalBindings["Theme"] === theme)
    }

    @MainActor
    func test_metadataFailure_doesNotApplyBindingsAndCanRetry() async throws {
        let commandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: commandQueue)
        let fileService = stateMachine.sourceArtboard.sourceFile.dependencies.fileService
        let theme = makeViewModelInstance(handle: 1, commandQueue: commandQueue)
        commandQueue.stubRequestGlobalViewModelNames { handle, requestID in
            fileService.onFileError(handle, requestID: requestID, message: "Metadata unavailable")
        }

        do {
            try await stateMachine.bindViewModelInstances(main: theme) {
                ("Theme", theme)
            }
            XCTFail("Expected metadata failure")
        } catch StateMachineError.error {}

        XCTAssertTrue(commandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(commandQueue.setGlobalViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(commandQueue.bindCalls.isEmpty)
        XCTAssertNil(stateMachine.mainBinding)
        XCTAssertTrue(stateMachine.globalBindings.isEmpty)

        commandQueue.stubRequestGlobalViewModelNames { handle, requestID in
            fileService.onGlobalViewModelsListed(handle, requestID: requestID, names: ["Theme"])
        }
        try await stateMachine.bindViewModelInstances {
            ("Theme", theme)
        }
        XCTAssertEqual(commandQueue.requestGlobalViewModelNamesCalls.count, 2)
        XCTAssertTrue(stateMachine.globalBindings["Theme"] === theme)
    }

    @MainActor
    func test_mainAndDefaultBindings_doNotRequestGlobalNames() async throws {
        let commandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: commandQueue)
        let main = makeViewModelInstance(handle: 1, commandQueue: commandQueue)
        try await stateMachine.bindViewModelInstances(main: main)
        try await stateMachine.bindViewModelInstances()
        XCTAssertTrue(commandQueue.requestGlobalViewModelNamesCalls.isEmpty)
        XCTAssertEqual(commandQueue.bindCalls.count, 2)
    }

    @MainActor
    func test_cancelledBinding_doesNotApplyCachedBindings() async throws {
        let commandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: commandQueue)
        let theme = makeViewModelInstance(handle: 1, commandQueue: commandQueue)
        _ = try await stateMachine.sourceArtboard.sourceFile.getGlobalViewModelNames()
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await stateMachine.bindViewModelInstances {
                ("Theme", theme)
            }
        }
        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch StateMachineError.cancelled {}
        XCTAssertTrue(commandQueue.setGlobalViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(commandQueue.bindCalls.isEmpty)
    }

    @MainActor
    func test_stateMachine_retainsParentsWithoutACycle() {
        let commandQueue = MockCommandQueue()
        var stateMachine: StateMachine? = makeStateMachine(commandQueue: commandQueue)
        weak var artboard = stateMachine?.sourceArtboard
        weak var file = stateMachine?.sourceArtboard.sourceFile
        XCTAssertNotNil(artboard)
        XCTAssertNotNil(file)
        stateMachine = nil
        XCTAssertNil(artboard)
        XCTAssertNil(file)
    }

    @MainActor
    func test_cancelledMetadataRequest_throwsStateMachineCancellationWithoutBinding() async throws {
        let commandQueue = MockCommandQueue()
        let stateMachine = makeStateMachine(commandQueue: commandQueue)
        let theme = makeViewModelInstance(handle: 1, commandQueue: commandQueue)
        let requested = expectation(description: "global names requested")
        commandQueue.stubRequestGlobalViewModelNames { _, _ in
            requested.fulfill()
        }
        let task = Task { @MainActor in
            try await stateMachine.bindViewModelInstances(main: theme) {
                ("Theme", theme)
            }
        }
        await fulfillment(of: [requested], timeout: 1)
        task.cancel()
        do {
            try await task.value
            XCTFail("Expected state machine cancellation")
        } catch StateMachineError.cancelled {}
        XCTAssertTrue(commandQueue.setViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(commandQueue.setGlobalViewModelInstanceCalls.isEmpty)
        XCTAssertTrue(commandQueue.bindCalls.isEmpty)
        XCTAssertNil(stateMachine.mainBinding)
        XCTAssertTrue(stateMachine.globalBindings.isEmpty)
    }

}
