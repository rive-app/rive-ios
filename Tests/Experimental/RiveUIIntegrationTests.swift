////
////  RiveUIIntegrationTests.swift
////  RiveRuntimeTests
////
////  Created by David Skuza on 8/6/25.
////  Copyright © 2025 Rive. All rights reserved.
////
//
//import XCTest
//@_spi(RiveExperimental) import RiveRuntime
//
//class RiveUIIntegrationTests: XCTestCase {
//    @MainActor
//    func test_file_withValidFile() async throws {
//        let worker = Worker()
//        let file: File
//        do {
//            file = try await File(source: .local("rive_ui", Bundle(for: Self.self)), worker: worker)
//        } catch {
//            XCTFail("file should not have errored")
//            return
//        }
//        
//        // Test artboard names functionality
//        let artboardNames = try await file.getArtboardNames()
//        XCTAssertNotNil(artboardNames)
//        XCTAssertEqual(artboardNames.count, 3)
//        
//        // Verify the specific artboard names are returned
//        XCTAssertTrue(artboardNames.contains("Artboard"))
//        XCTAssertTrue(artboardNames.contains("Artboard 2"))
//        XCTAssertTrue(artboardNames.contains("Artboard 3"))
//        
//        // Test default artboard creation
//        let defaultArtboard = try await file.createArtboard()
//        XCTAssertNotNil(defaultArtboard)
//        
//        // Test named artboard creation (using actual artboard names)
//        let namedArtboard1 = try await file.createArtboard("Artboard")
//        XCTAssertNotNil(namedArtboard1)
//        
//        let namedArtboard2 = try await file.createArtboard("Artboard 2")
//        XCTAssertNotNil(namedArtboard2)
//        
//        let namedArtboard3 = try await file.createArtboard("Artboard 3")
//        XCTAssertNotNil(namedArtboard3)
//
//        let stateMachineNames = try await namedArtboard1.getStateMachineNames()
//        XCTAssertEqual(stateMachineNames.count, 2)
//        XCTAssertTrue(stateMachineNames.contains("State Machine 1"))
//        XCTAssertTrue(stateMachineNames.contains("State Machine 2"))
//
//        let defaultStateMachine = try await namedArtboard1.createStateMachine()
//        XCTAssertNotNil(defaultStateMachine)
//
//        let namedStateMachine1 = try await namedArtboard1.createStateMachine("State Machine 1")
//        XCTAssertNotNil(namedStateMachine1)
//
//        let namedStateMachine2 = try await namedArtboard1.createStateMachine("State Machine 2")
//        XCTAssertNotNil(namedStateMachine2)
//
//        let viewModelNames = try await file.getViewModelNames()
//        XCTAssertEqual(Set(viewModelNames), ["ViewModel", "NestedViewModel"])
//        
//        // Test enum retrieval
//        let enums = try await file.getViewModelEnums()
//        let fooEnum = enums.first { $0.name == "Foo" }
//        XCTAssertEqual(fooEnum?.values, ["foo", "bar", "baz"])
//    }
//
//    @MainActor
//    func test_file_withInvalidFile() async {
//        let worker = Worker()
//        do {
//            _ = try await File(source: .local("rive_ui_invalid", Bundle(for: Self.self)), worker: worker)
//            XCTFail("Error should be thrown")
//        } catch {
//            guard let uiError = error as? RiveUIError, case .invalidFile = uiError else {
//                XCTFail("Incorrect error type")
//                return
//            }
//        }
//    }
//
//    @MainActor
//    private func setupDataBindingViewModel() async throws -> (file: File, stateMachine: StateMachine, viewModelInstance: ViewModelInstance) {
//        let worker = Worker()
//        let file = try await File(source: .local("rive_ui", Bundle(for: Self.self)), worker: worker)
//        let artboard = try await file.createArtboard("Data Binding")
//        let stateMachine = try await artboard.createStateMachine()
//        let viewModelInstance = try await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
//        stateMachine.bindViewModelInstance(viewModelInstance)
//        return (file, stateMachine, viewModelInstance)
//    }
//
//    @MainActor
//    func test_dataBinding_stringProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//
//        let stringProperty = StringProperty(path: "string")
//        var stringValue = try await viewModelInstance.value(of: stringProperty)
//        XCTAssertEqual(stringValue, "Text")
//        viewModelInstance.setValue(of: stringProperty, to: "Updated")
//        stateMachine.advance(by: 0)
//        stringValue = try await viewModelInstance.value(of: stringProperty)
//        XCTAssertEqual(stringValue, "Updated")
//        
//        let valueStream = viewModelInstance.valueStream(of: stringProperty)
//        var collectedValues: [String] = []
//        let expectation = expectation(description: "valueStream should collect 3 values")
//        
//        let streamTask = Task {
//            for try await value in valueStream {
//                collectedValues.append(value)
//                if collectedValues.count >= 3 {
//                    expectation.fulfill()
//                    break
//                }
//            }
//        }
//        
//        viewModelInstance.setValue(of: stringProperty, to: "1")
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: stringProperty, to: "2")
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: stringProperty, to: "3")
//        stateMachine.advance(by: 0)
//
//        await fulfillment(of: [expectation], timeout: 1.0)
//        streamTask.cancel()
//        
//        XCTAssertEqual(collectedValues, ["1", "2", "3"])
//    }
//    
//    @MainActor
//    func test_dataBinding_boolProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//
//        let boolProperty = BoolProperty(path: "boolean")
//        var boolValue = try await viewModelInstance.value(of: boolProperty)
//        XCTAssertEqual(boolValue, false)
//        viewModelInstance.setValue(of: boolProperty, to: true)
//        stateMachine.advance(by: 0)
//        boolValue = try await viewModelInstance.value(of: boolProperty)
//        XCTAssertEqual(boolValue, true)
//        
//        let valueStream = viewModelInstance.valueStream(of: boolProperty)
//        var collectedValues: [Bool] = []
//        let expectation = expectation(description: "valueStream should collect 3 values")
//        
//        let streamTask = Task {
//            for try await value in valueStream {
//                collectedValues.append(value)
//                if collectedValues.count >= 3 {
//                    expectation.fulfill()
//                    break
//                }
//            }
//        }
//        
//        viewModelInstance.setValue(of: boolProperty, to: false)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: boolProperty, to: true)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: boolProperty, to: false)
//        stateMachine.advance(by: 0)
//        
//        await fulfillment(of: [expectation], timeout: 1.0)
//        streamTask.cancel()
//        
//        XCTAssertEqual(collectedValues, [false, true, false])
//    }
//    
//    @MainActor
//    func test_dataBinding_enumProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//        
//        let enumProperty = EnumProperty(path: "enum")
//        var enumValue = try await viewModelInstance.value(of: enumProperty)
//        XCTAssertEqual(enumValue, "foo")
//        viewModelInstance.setValue(of: enumProperty, to: "bar")
//        stateMachine.advance(by: 0)
//        enumValue = try await viewModelInstance.value(of: enumProperty)
//        XCTAssertEqual(enumValue, "bar")
//        
//        let valueStream = viewModelInstance.valueStream(of: enumProperty)
//        var collectedValues: [String] = []
//        let expectation = expectation(description: "valueStream should collect 3 values")
//        
//        let streamTask = Task {
//            for try await value in valueStream {
//                collectedValues.append(value)
//                if collectedValues.count >= 3 {
//                    expectation.fulfill()
//                    break
//                }
//            }
//        }
//        
//        viewModelInstance.setValue(of: enumProperty, to: "foo")
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: enumProperty, to: "bar")
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: enumProperty, to: "baz")
//        stateMachine.advance(by: 0)
//        
//        await fulfillment(of: [expectation], timeout: 1.0)
//        streamTask.cancel()
//        
//        XCTAssertEqual(collectedValues, ["foo", "bar", "baz"])
//    }
//    
//    @MainActor
//    func test_dataBinding_colorProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//        
//        let colorProperty = ColorProperty(path: "color")
//        var colorValue = try await viewModelInstance.value(of: colorProperty)
//        XCTAssertEqual(colorValue, Color(red: 0, green: 0, blue: 0, alpha: 255))
//        let updatedColor = Color(red: 255, green: 255, blue: 255, alpha: 255)
//        viewModelInstance.setValue(of: colorProperty, to: updatedColor)
//        stateMachine.advance(by: 0)
//        colorValue = try await viewModelInstance.value(of: colorProperty)
//        XCTAssertEqual(colorValue, Color(red: 255, green: 255, blue: 255, alpha: 255))
//        
//        let valueStream = viewModelInstance.valueStream(of: colorProperty)
//        var collectedValues: [Color] = []
//        let expectation = expectation(description: "valueStream should collect 3 values")
//        
//        let streamTask = Task {
//            for try await value in valueStream {
//                collectedValues.append(value)
//                if collectedValues.count >= 3 {
//                    expectation.fulfill()
//                    break
//                }
//            }
//        }
//        
//        let color1 = Color(red: 255, green: 0, blue: 0, alpha: 255)
//        let color2 = Color(red: 0, green: 255, blue: 0, alpha: 255)
//        let color3 = Color(red: 0, green: 0, blue: 255, alpha: 255)
//        viewModelInstance.setValue(of: colorProperty, to: color1)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: colorProperty, to: color2)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: colorProperty, to: color3)
//        stateMachine.advance(by: 0)
//        
//        await fulfillment(of: [expectation], timeout: 1.0)
//        streamTask.cancel()
//        
//        XCTAssertEqual(collectedValues, [color1, color2, color3])
//    }
//    
//    @MainActor
//    func test_dataBinding_numberProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//        
//        let numberProperty = NumberProperty(path: "number")
//        var numberValue = try await viewModelInstance.value(of: numberProperty)
//        XCTAssertEqual(numberValue, 0.0)
//        viewModelInstance.setValue(of: numberProperty, to: 42.5)
//        stateMachine.advance(by: 0)
//        numberValue = try await viewModelInstance.value(of: numberProperty)
//        XCTAssertEqual(numberValue, 42.5)
//        
//        let valueStream = viewModelInstance.valueStream(of: numberProperty)
//        var collectedValues: [Float] = []
//        let expectation = expectation(description: "valueStream should collect 3 values")
//        
//        let streamTask = Task {
//            for try await value in valueStream {
//                collectedValues.append(value)
//                if collectedValues.count >= 3 {
//                    expectation.fulfill()
//                    break
//                }
//            }
//        }
//        
//        viewModelInstance.setValue(of: numberProperty, to: 1.0)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: numberProperty, to: 2.0)
//        stateMachine.advance(by: 0)
//        viewModelInstance.setValue(of: numberProperty, to: 3.0)
//        stateMachine.advance(by: 0)
//        
//        await fulfillment(of: [expectation], timeout: 1.0)
//        streamTask.cancel()
//        
//        XCTAssertEqual(collectedValues, [1.0, 2.0, 3.0])
//    }
//
//    @MainActor
//    func test_dataBinding_viewModelInstanceProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//        
//        let nestedViewModelInstanceProperty = ViewModelInstanceProperty(path: "nestedViewModel")
//        let nestedViewModelInstance = viewModelInstance.value(of: nestedViewModelInstanceProperty)
//        
//        let nestedStringProperty = StringProperty(path: "string")
//        var nestedStringValue = try await nestedViewModelInstance.value(of: nestedStringProperty)
//        XCTAssertEqual(nestedStringValue, "Initial value")
//        nestedViewModelInstance.setValue(of: nestedStringProperty, to: "Nested Updated")
//        stateMachine.advance(by: 0)
//        nestedStringValue = try await nestedViewModelInstance.value(of: nestedStringProperty)
//        XCTAssertEqual(nestedStringValue, "Nested Updated")
//    }
//    
//    @MainActor
//    func test_dataBinding_listProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        
//        // Test initial list size
//        let listProperty = ListProperty(path: "list")
//        let listSize = try await viewModelInstance.size(of: listProperty)
//        XCTAssertEqual(listSize, 3)
//
//        // Test getting and setting a value of the first list item
//        let listItemViewModelInstance = viewModelInstance.value(of: listProperty, at: 0)
//        let listItemStringProperty = StringProperty(path: "string")
//        var listItemStringValue = try await listItemViewModelInstance.value(of: listItemStringProperty)
//        XCTAssertEqual(listItemStringValue, "Initial value")
//        listItemViewModelInstance.setValue(of: listItemStringProperty, to: "List Item Updated")
//        stateMachine.advance(by: 0)
//        listItemStringValue = try await listItemViewModelInstance.value(of: listItemStringProperty)
//        XCTAssertEqual(listItemStringValue, "List Item Updated")
//
//        // Test appending a new list item
//        let appendedListItemViewModelInstance = try await file.createViewModelInstance(.viewModelDefault(from: .name("NestedViewModel")))
//        appendedListItemViewModelInstance.setValue(of: StringProperty(path: "string"), to: "Inserted")
//        stateMachine.advance(by: 0)
//        viewModelInstance.appendInstance(appendedListItemViewModelInstance, to: listProperty)
//        var newListSize = try await viewModelInstance.size(of: listProperty)
//        XCTAssertEqual(newListSize, 4)
//
//        // Test inserting a new list item at the end
//        let insertedListItemViewModelInstance = try await file.createViewModelInstance(.viewModelDefault(from: .name("NestedViewModel")))
//        insertedListItemViewModelInstance.setValue(of: StringProperty(path: "string"), to: "Appended")
//        stateMachine.advance(by: 0)
//        viewModelInstance.insertInstance(insertedListItemViewModelInstance, to: listProperty, at: Int32(newListSize))
//        newListSize = try await viewModelInstance.size(of: listProperty)
//        XCTAssertEqual(newListSize, 5)
//
//        // Test swapping two list items (index 0 with appended)
//        viewModelInstance.swapInstance(atIndex: 0, withIndex: Int32(newListSize) - 1, in: listProperty)
//        let swappedListItemViewModelInstance = viewModelInstance.value(of: listProperty, at: 0)
//        let swappedStringValue = try await swappedListItemViewModelInstance.value(of: StringProperty(path: "string"))
//        XCTAssertEqual(swappedStringValue, "Appended")
//
//        // Test removing a list item by instance
//        viewModelInstance.removeInstance(swappedListItemViewModelInstance, from: listProperty)
//        newListSize = try await viewModelInstance.size(of: listProperty)
//        XCTAssertEqual(newListSize, 4)
//
//        // Test removing a list item by index
//        viewModelInstance.removeInstance(at: 0, from: listProperty)
//        newListSize = try await viewModelInstance.size(of: listProperty)
//        XCTAssertEqual(newListSize, 3)
//    }
//    
//    @MainActor
//    func test_dataBinding_triggerProperty() async throws {
//        let (file, stateMachine, viewModelInstance) = try await setupDataBindingViewModel()
//        _ = file
//        
//        let triggerProperty = TriggerProperty(path: "trigger")
//        viewModelInstance.fire(trigger: triggerProperty)
//        stateMachine.advance(by: 0)
//        // Trigger doesn't return a value, so we just verify it doesn't crash
//    }
//    
//    @MainActor
//    func test_dataBinding_imageProperty() async throws {
//        XCTFail("Test not implemented: setValue(of: ImageProperty, to: Image)")
//    }
//}
