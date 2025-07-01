//
//  DataBindingTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 1/15/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@testable import RiveRuntime

class DataBindingTests: XCTestCase {
    let file: RiveFile = try! RiveFile(testfileName: "data_binding_test")

    // MARK: - RiveFile

    func test_file_ViewModelAtIndex_atIndex_returnsViewModelOrNil() {
        XCTAssertNotNil(file.viewModel(at: 0))
        XCTAssertNotNil(file.viewModel(at: 1))
        XCTAssertNotNil(file.viewModel(at: 2))

        XCTAssertNil(file.viewModel(at: 3))
    }

    func testViewModel_named_returnsViewModelOrNil() {
        XCTAssertNotNil(file.viewModelNamed("Test"))
        XCTAssertNotNil(file.viewModelNamed("Nested"))

        XCTAssertNil(file.viewModelNamed("404"))
    }

    // MARK: - RiveDataBindingViewModel

    func test_viewModel_createInstance_fromIndex_returnsInstanceOrNil() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertNotNil(viewModel.createInstance(fromIndex: 0))
        XCTAssertNotNil(viewModel.createInstance(fromIndex: 1))
        XCTAssertNil(viewModel.createInstance(fromIndex: 2))
    }

    func test_viewModel_createInstance_fromName_returnsInstanceOrNil() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertNotNil(viewModel.createInstance(fromName: "Default"))
        XCTAssertNil(viewModel.createInstance(fromName: "404"))
    }

    func test_viewModel_createDefaultInstance_returnsInstance() {
        var viewModel = file.viewModelNamed("Test")
        XCTAssertNotNil(viewModel?.createDefaultInstance())

        viewModel = file.viewModelNamed("Default")
        XCTAssertNotNil(viewModel?.createDefaultInstance())
    }

    func test_viewModel_createInstance_returnsBlankInstance() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertNotNil(viewModel.createInstance())
    }

    func test_viewModel_instanceCount_returnsNames() {
        var viewModel = file.viewModelNamed("Test")!
        XCTAssertEqual(viewModel.instanceCount, 2)

        // "Default" has no explicit instances; it only has the default created by the editor
        viewModel = file.viewModelNamed("Default")!
        XCTAssertEqual(viewModel.instanceCount, 1)
    }

    func test_viewModel_instanceNames_withInstances_returnsNames() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertEqual(Set(viewModel.instanceNames), ["Editor Defaults", "Default"])
    }

    func test_viewModel_instanceNames_withoutInstances_returnsDefault() {
        let viewModel = file.viewModelNamed("Default")!
        XCTAssertEqual(viewModel.instanceNames, [""])
    }

    func test_viewModel_name_returnsName() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertEqual(viewModel.name, "Test")
    }

    func test_viewModel_propertyCount_returnsCount() {
        let viewModel = file.viewModelNamed("Test")!
        XCTAssertEqual(viewModel.propertyCount, 10)
    }

    func test_viewModel_properties_returnsAllProperties() {
        let viewModel = file.viewModelNamed("Test")!

        XCTAssertEqual(viewModel.properties.count, 10)

        var data = viewModel.properties[0]
        XCTAssertEqual(data.type, .viewModel)
        XCTAssertEqual(data.name, "SecondNested")

        data = viewModel.properties[1]
        XCTAssertEqual(data.type, .trigger)
        XCTAssertEqual(data.name, "Trigger Blue")

        data = viewModel.properties[2]
        XCTAssertEqual(data.type, .trigger)
        XCTAssertEqual(data.name, "Trigger Green")

        data = viewModel.properties[3]
        XCTAssertEqual(data.type, .trigger)
        XCTAssertEqual(data.name, "Trigger Red")

        data = viewModel.properties[4]
        XCTAssertEqual(data.type, .viewModel)
        XCTAssertEqual(data.name, "Nested")

        data = viewModel.properties[5]
        XCTAssertEqual(data.type, .enum)
        XCTAssertEqual(data.name, "Enum")

        data = viewModel.properties[6]
        XCTAssertEqual(data.type, .color)
        XCTAssertEqual(data.name, "Color")

        data = viewModel.properties[7]
        XCTAssertEqual(data.type, .boolean)
        XCTAssertEqual(data.name, "Boolean")

        data = viewModel.properties[8]
        XCTAssertEqual(data.type, .number)
        XCTAssertEqual(data.name, "Number")

        data = viewModel.properties[9]
        XCTAssertEqual(data.type, .string)
        XCTAssertEqual(data.name, "String")
    }

    // MARK: - RiveDataBindingViewModelInstance

    func test_viewModelInstance_name_returnsName() {
        let viewModel = file.viewModelNamed("Test")!

        var instance = viewModel.createInstance(fromName: "Default")
        XCTAssertEqual(instance?.name, "Default")

        instance = viewModel.createInstance(fromName: "Editor Defaults")
        XCTAssertEqual(instance?.name, "Editor Defaults")
    }

    // MARK: Property

    func test_viewModelInstance_property() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.property(fromPath: "String"))
        XCTAssertNil(instance.property(fromPath: "404"))
    }

    func test_viewModelInstance_property_onDealloc_removedFromStore() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        var property = instance.property(fromPath: "String")
        let observer = property?.observe(\.hasChanged) { _, _ in }
        observer?.invalidate()
        property = nil
    }

    // Tests _memory_ equality of objects to ensure they are properly cached
    // within their parent instance and reused.
    func test_viewModelInstance_properties_withoutPath_isCachedByRoot() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        
        let property = instance.property(fromPath: "String")!
        let cachedProperty = instance.property(fromPath: "String")!
        XCTAssertTrue(property === cachedProperty)

        let stringProperty = instance.stringProperty(fromPath: "String")!
        let cachedStringProperty = instance.stringProperty(fromPath: "String")!
        XCTAssertTrue(stringProperty === cachedStringProperty)

        let numberProperty = instance.numberProperty(fromPath: "Number")!
        let cachedNumberProperty = instance.numberProperty(fromPath: "Number")!
        XCTAssertTrue(numberProperty === cachedNumberProperty)

        let booleanProperty = instance.booleanProperty(fromPath: "Boolean")!
        let cachedBooleanProperty = instance.booleanProperty(fromPath: "Boolean")!
        XCTAssertTrue(booleanProperty === cachedBooleanProperty)

        let colorProperty = instance.colorProperty(fromPath: "Color")!
        let cachedColorProperty = instance.colorProperty(fromPath: "Color")!
        XCTAssertTrue(colorProperty === cachedColorProperty)

        let enumProperty = instance.enumProperty(fromPath: "Enum")!
        let cachedEnumProperty = instance.enumProperty(fromPath: "Enum")!
        XCTAssertTrue(enumProperty === cachedEnumProperty)

        let triggerProperty = instance.triggerProperty(fromPath: "Trigger Red")!
        let cachedTriggerProperty = instance.triggerProperty(fromPath: "Trigger Red")!
        XCTAssertTrue(triggerProperty === cachedTriggerProperty)
    }

    // Tests _memory_ equality of objects to ensure they are properly cached
    // within their parent instance and reused, where nested components are
    // cached by the correct child instance (thus becoming a property's parent).
    func test_viewModelInstance_properties_withPath_isCachedByNestedRoot() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let stringPropertyByPath = instance.stringProperty(fromPath: "Nested/String")!

        let stringPropertyFromNested = instance.viewModelInstanceProperty(fromPath: "Nested")?.stringProperty(fromPath: "String")

        let nested = instance.viewModelInstanceProperty(fromPath: "Nested")!
        let nestedStringProperty = nested.stringProperty(fromPath: "String")!

        XCTAssertTrue(stringPropertyByPath === stringPropertyFromNested)
        XCTAssertTrue(stringPropertyFromNested === nestedStringProperty)
    }

    // MARK: String

    func test_viewModelInstance_stringProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.stringProperty(fromPath: "String"))
        XCTAssertNil(instance.stringProperty(fromPath: "404"))
    }

    func test_viewModelInstance_stringProperty_setsValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.stringProperty(fromPath: "String")!
        XCTAssertEqual(property.value, "Text")

        // This, and similar tests below, verify that we are calling
        // into the c++ runtime to set / get the value.
        let newValue = "XCTest"
        property.value = newValue
        XCTAssertEqual(property.value, newValue)
    }

    // MARK: Number

    func test_viewModelInstance_numberProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.numberProperty(fromPath: "Number"))
        XCTAssertNil(instance.numberProperty(fromPath: "404"))
    }

    func test_viewModelInstance_numberProperty_setsValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.numberProperty(fromPath: "Number")!
        XCTAssertEqual(property.value, 0)

        let newValue: Float = 1337
        property.value = newValue
        XCTAssertEqual(property.value, newValue)
    }

    // MARK: Boolean

    func test_viewModelInstance_booleanProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.booleanProperty(fromPath: "Boolean"))
        XCTAssertNil(instance.booleanProperty(fromPath: "404"))
    }

    func test_viewModelInstance_booleanProperty_setsValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.booleanProperty(fromPath: "Boolean")!
        XCTAssertEqual(property.value, false)

        let newValue = true
        property.value = newValue
        XCTAssertEqual(property.value, newValue)
    }

    // MARK: Color

    func test_viewModelInstance_colorProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.colorProperty(fromPath: "Color"))
        XCTAssertNil(instance.colorProperty(fromPath: "404"))
    }

    func test_viewModelInstance_colorProperty_setsValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.colorProperty(fromPath: "Color")!
        XCTAssertEqual(Color(property.value), Color(.black))

        let updatedColor = UIColor(red: 0x1D / 255, green: 0x1D / 255, blue: 0x1D / 255, alpha: 0x1D / 255)
        property.value = updatedColor
        XCTAssertEqual(Color(property.value), Color(updatedColor))

        property.set(red: 0, green: 0, blue: 0, alpha: 0xFF)
        XCTAssertEqual(Color(property.value), Color(.black))

        // Test clamping floats 0...1

        property.set(red: 2, green: 2, blue: 2, alpha: 2)
        XCTAssertEqual(Color(property.value), Color(.white))

        property.set(red: -1, green: -1, blue: -1, alpha: -1)
        XCTAssertEqual(Color(property.value), Color(.clear))

        // "Reset" for the next test by testing alpha

        property.setAlpha(1)
        XCTAssertEqual(Color(property.value), Color(.black))

        property.set(red: 0xFF / 255, green: 0xFF / 255, blue: 0xFF / 255)
        XCTAssertEqual(Color(property.value), Color(.white))

        // Test clamping floats 0...1
        // "Resets" the color to white so that we don't
        // have to test against an alpha value
        property.value = .white

        property.set(red: 2, green: 2, blue: 2)
        XCTAssertEqual(Color(property.value), Color(.white))

        property.set(red: -1, green: -1, blue: -1)
        XCTAssertEqual(Color(property.value), Color(.black))
    }

    // MARK: Enum

    func test_viewModelInstance_enumProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.enumProperty(fromPath: "Enum"))
        XCTAssertNil(instance.enumProperty(fromPath: "404"))
    }

    func test_viewModelInstance_enumProperty_containsAllValues() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.enumProperty(fromPath: "Enum")!
        XCTAssertEqual(Set(property.values), Set(["Foo", "Bar", "Baz"]))
    }

    func test_viewModelInstance_enumProperty_setsValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.enumProperty(fromPath: "Enum")!
        XCTAssertEqual(property.value, "Foo")

        var newValue = "Bar"
        property.value = newValue
        XCTAssertEqual(property.value, newValue)

        newValue = "Baz"
        property.value = newValue
        XCTAssertEqual(property.value, newValue)

        newValue = "404"
        property.value = newValue
        XCTAssertEqual(property.value, "Baz")
    }

    func test_viewModelInstance_enumProperty_setsValueIndex() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.enumProperty(fromPath: "Enum")!
        XCTAssertEqual(property.value, "Foo")
        XCTAssertEqual(property.valueIndex, 2)

        var newValue = "Bar"
        property.value = newValue
        XCTAssertEqual(property.value, newValue)
        XCTAssertEqual(property.valueIndex, 1)

        newValue = "Baz"
        property.value = newValue
        XCTAssertEqual(property.value, newValue)
        XCTAssertEqual(property.valueIndex, 0)

        newValue = "404"
        property.value = newValue
        XCTAssertEqual(property.value, "Baz")
        XCTAssertEqual(property.valueIndex, 0)
    }

    // MARK: View Model

    func test_viewModelInstance_viewModelProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.viewModelInstanceProperty(fromPath: "Nested"))
        XCTAssertNil(instance.viewModelInstanceProperty(fromPath: "404"))
    }

    func test_viewModelInstance_viewModelProperty_setsNestedValue() {
        let property = file.viewModelNamed("Test")!.createDefaultInstance()!.viewModelInstanceProperty(fromPath: "Nested")!
        let nestedProperty = property.stringProperty(fromPath: "String")
        XCTAssertNotNil(nestedProperty)
        XCTAssertEqual(nestedProperty!.value, "Nested")

        let newValue = "XCTest"
        nestedProperty!.value = newValue
        XCTAssertEqual(nestedProperty!.value, newValue)
    }

    func test_viewModelInstance_nested_areIdentical() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!

        let fromPath = instance.viewModelInstanceProperty(fromPath: "Nested/DeeperNested")!
        let nested = instance.viewModelInstanceProperty(fromPath: "Nested")!.viewModelInstanceProperty(fromPath: "DeeperNested")!
        XCTAssertIdentical(fromPath, nested)
    }

    func test_viewModelInstance_replace_withCorrectInstance_setsNewInstance() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertEqual(instance.stringProperty(fromPath: "Nested/String")!.value, "Nested")

//         Test one-level deep + caching
        let replacement = file.viewModelNamed("Nested")!.createInstance()!
        replacement.stringProperty(fromPath: "String")!.value = "Hello, Rive"
        var replaced = instance.setViewModelInstanceProperty(fromPath: "Nested", to: replacement)
        XCTAssertTrue(replaced)
        XCTAssertEqual(instance.stringProperty(fromPath: "Nested/String")!.value, "Hello, Rive")
        XCTAssertIdentical(
            instance.viewModelInstanceProperty(fromPath: "Nested"),
            replacement
        )

//         Test two-level deep traversal + caching
        let nestedReplacement = file.viewModelNamed("Default")!.createDefaultInstance()!
        replaced = instance.setViewModelInstanceProperty(fromPath: "Nested/DeeperNested", to: nestedReplacement)
        XCTAssertTrue(replaced)
        XCTAssertIdentical(
            instance.viewModelInstanceProperty(fromPath: "Nested/DeeperNested")!,
            nestedReplacement
        )

        XCTAssertIdentical(
            instance.viewModelInstanceProperty(fromPath: "Nested/DeeperNested")!,
            instance.viewModelInstanceProperty(fromPath: "Nested")!.viewModelInstanceProperty(fromPath: "DeeperNested")
        )

        XCTAssertEqual(
            instance.stringProperty(fromPath: "Nested/DeeperNested/String")!.value,
            instance.viewModelInstanceProperty(fromPath: "Nested")!
                .viewModelInstanceProperty(fromPath: "DeeperNested")!
                .stringProperty(fromPath: "String")!.value
        )
    }

    func test_viewModelInstance_replace_withIncorrectInstance_returnsFalse() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let replacement = file.viewModelNamed("Default")!.createInstance()!
        let replaced = instance.setViewModelInstanceProperty(fromPath: "Nested", to: replacement)
        XCTAssertFalse(replaced)
    }

    // MARK: Trigger

    func test_viewModelInstance_triggerProperty_returnsPropertyOrNil() {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        XCTAssertNotNil(instance.triggerProperty(fromPath: "Trigger Red"))
        XCTAssertNotNil(instance.triggerProperty(fromPath: "Trigger Green"))
        XCTAssertNotNil(instance.triggerProperty(fromPath: "Trigger Blue"))
        XCTAssertNil(instance.triggerProperty(fromPath: "404"))
    }

    // MARK: Image

    func test_viewModelInstance_imageProperty_returnsPropertyOrNil() throws {
        let file = try RiveFile(testfileName: "data_binding_image_test")
        let instance = file.viewModelNamed("vm")!.createDefaultInstance()!
        XCTAssertNotNil(instance.imageProperty(fromPath: "img"))
        XCTAssertNil(instance.imageProperty(fromPath: "404"))
    }

    func test_viewModelInstance_imageProperty_canSetValue() throws {
        let file = try RiveFile(testfileName: "data_binding_image_test")
        let instance = file.viewModelNamed("vm")!.createDefaultInstance()!
        let property = instance.imageProperty(fromPath: "img")!

        let bundle = Bundle(for: type(of: self))
        let fileURL = bundle.url(forResource: "1x1_jpg", withExtension: "jpg")!
        let data = try Data(contentsOf: fileURL)
        let renderImage = RiveRenderImage(data: data)!
        property.setValue(renderImage)
        XCTAssertTrue(property.hasChanged)
    }

    // MARK: Binding

    func test_binding_artboard_stringProperty_updatesTextRun() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        artboard.bind(viewModelInstance: instance)
        instance.stringProperty(fromPath: "String")?.value = "Test"
        artboard.advance(by: 0)
        XCTAssertEqual(artboard.textRun("String")?.text(), "Test")
    }

    func test_binding_stateMachine_booleanProperty_updatesState() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        instance.booleanProperty(fromPath: "Boolean")?.value = true
        stateMachine.advance(by: 0)
    }

    // MARK: - AutoBind

    func test_riveModel_autoBind_artboard() throws {
        let model = RiveModel(riveFile: file)

        let expectation = expectation(description: "autoBind callback")
        expectation.expectedFulfillmentCount = 3
        var instance: RiveDataBindingViewModel.Instance?

        model.enableAutoBind { i in
            instance = i
            expectation.fulfill()
        }

        try model.setArtboard("Artboard")
        try model.setArtboard()
        try model.setArtboard(0)
        wait(for: [expectation], timeout: 1)

        let stringProperty = instance?.stringProperty(fromPath: "String")
        stringProperty?.value = "Test"
        let textRun = model.artboard?.textRun("String")
        model.artboard.advance(by: 0)
        XCTAssertEqual(textRun?.text(), "Test")
    }

    func test_riveModel_autoBind_stateMachine() throws {
        let model = RiveModel(riveFile: file)

        let expectation = expectation(description: "autoBind callback")
        expectation.expectedFulfillmentCount = 3
        var instance: RiveDataBindingViewModel.Instance?

        model.enableAutoBind { i in
            instance = i
            expectation.fulfill()
        }

        try model.setArtboard()
        try model.setStateMachine("State Machine 1")
        try model.setStateMachine()
        wait(for: [expectation], timeout: 1)

        let booleanProperty = instance?.booleanProperty(fromPath: "Boolean")
        booleanProperty?.value = true
        model.stateMachine?.advance(by: 0)
        XCTAssertNotNil(model.stateMachine?.stateChanges().firstIndex(of: "boolean_on"))
    }

    func test_riveModel_autoBind_withArtboardAlreadySet() throws {
        let model = RiveModel(riveFile: file)
        try model.setArtboard()

        let expectation = expectation(description: "autoBind callback")
        model.enableAutoBind { _ in
            expectation.fulfill()
        }

        wait(for: [expectation])
    }

    func test_riveModel_autoBind_enableThenDisable() throws {
        let model = RiveModel(riveFile: file)

        let expectation = expectation(description: "autoBind callback")
        expectation.isInverted = true
        model.enableAutoBind { _ in
            expectation.fulfill()
        }
        model.disableAutoBind()
        try model.setArtboard()

        wait(for: [expectation], timeout: 0.1)
    }

    func test_riveViewModel_riveModel_autoBind_fromDefaults() throws {
        let model = RiveModel(riveFile: file)
        let expectation = expectation(description: "autoBind callback")
        expectation.expectedFulfillmentCount = 2
        model.enableAutoBind { _ in
            expectation.fulfill()
        }

        _ = RiveViewModel(model)
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Property Listeners

    func test_stringProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let string = instance.stringProperty(fromPath: "String")!
        let listener = string.addListener { value in
            XCTAssertEqual(value, "Foo")
            addExpectation.fulfill()
        }

        string.value = "Foo"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        string.removeListener(listener)
        string.value = "Bar"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_numberProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let number = instance.numberProperty(fromPath: "Number")!
        let listener = number.addListener { value in
            XCTAssertEqual(value, 1)
            addExpectation.fulfill()
        }

        // Prematurely advance by 0 because there's a quirk in the test
        // state machine that on first advance sets the number to 0
        stateMachine.advance(by: 0)
        number.value = 1
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        number.removeListener(listener)
        number.value = 2
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_booleanProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let boolean = instance.booleanProperty(fromPath: "Boolean")!
        let listener = boolean.addListener { value in
            XCTAssertEqual(value, true)
            addExpectation.fulfill()
        }

        boolean.value = true
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        boolean.removeListener(listener)
        boolean.value = false
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_colorProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let color = instance.colorProperty(fromPath: "Color")!
        let listener = color.addListener { value in
            XCTAssertEqual(Color(value), Color(.red))
            addExpectation.fulfill()
        }

        color.value = .red
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        color.removeListener(listener)
        color.value = .white
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_enumProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let property = instance.enumProperty(fromPath: "Enum")!
        let last = property.values.first!
        let listener = property.addListener { value in
            XCTAssertEqual(value, last)
            addExpectation.fulfill()
        }

        property.value = last
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        property.removeListener(listener)
        property.value = property.values.first!
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_triggerProperty_listener_canAddAndRemoveListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let addExpectation = expectation(description: "listener called")

        let property = instance.triggerProperty(fromPath: "Trigger Red")!
        let listener = property.addListener {
            addExpectation.fulfill()
        }

        property.trigger()
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [addExpectation], timeout: 1)

        let removeExpectation = expectation(description: "listener called")
        removeExpectation.isInverted = true
        property.removeListener(listener)
        property.trigger()
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [removeExpectation], timeout: 1)
    }

    func test_property_listener_afterAddingSingleListener_callsListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        string.addListener { _ in
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_afterAddingAndRemovingSingleListener_doesNotCallListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.isInverted = true
        let uuid = string.addListener { _ in
            expectation.fulfill()
        }
        string.removeListener(uuid)

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_afterAddingMultipleListeners_callsListeners() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.expectedFulfillmentCount = 2
        string.addListener { _ in
            expectation.fulfill()
        }
        string.addListener { _ in
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_afterAddingAndRemovingMultipleListeners_callsListeners() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.isInverted = true
        let uuid1 = string.addListener { _ in
            expectation.fulfill()
        }
        let uuid2 = string.addListener { _ in
            expectation.fulfill()
        }
        string.removeListener(uuid1)
        string.removeListener(uuid2)

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_afterAddingTwoAndRemovingOneListener_callsListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.expectedFulfillmentCount = 1
        let uuid1 = string.addListener { _ in
            expectation.fulfill()
        }
        string.addListener { _ in
            expectation.fulfill()
        }
        string.removeListener(uuid1)

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_addingTwo_updatingOne_callsOneListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.expectedFulfillmentCount = 1
        string.addListener { _ in
            expectation.fulfill()
        }
        let number = instance.numberProperty(fromPath: "Number")!
        number.addListener { _ in
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_property_listener_addingTwo_callsBoth_thenResets() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.expectedFulfillmentCount = 2

        string.addListener { _ in
            XCTAssertTrue(string.hasChanged)
            expectation.fulfill()
        }

        string.addListener { _ in
            XCTAssertTrue(string.hasChanged)
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)

        XCTAssertFalse(string.hasChanged)
    }

    func test_view_listener_afterAddingOneListener_onAdvance_callsListener() throws {
        let model = RiveModel(riveFile: file)
        let viewModel = RiveViewModel(model, autoPlay: false)

        let instance = model.riveFile.viewModelNamed("Test")!.createDefaultInstance()!
        viewModel.riveModel!.stateMachine!.bind(viewModelInstance: instance)

        let string = instance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        string.addListener { _ in
            expectation.fulfill()
        }
        instance.numberProperty(fromPath: "Number")!.addListener { _ in
            // This should not be called, since number was never updated
            expectation.fulfill()
        }

        let view = viewModel.createRiveView()

        string.value = "Listener"
        view.play() // == .advance(delta: 0)
        wait(for: [expectation], timeout: 1)
    }

    func test_nestedViewModel_property_withReference_afterAddingSingleListener_callsListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let nestedInstance = instance.viewModelInstanceProperty(fromPath: "Nested")!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = nestedInstance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        string.addListener { _ in
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_nestedViewModel_property_withNoReference_afterAddingSingleListener_callsListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        let string = instance.viewModelInstanceProperty(fromPath: "Nested")!.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        string.addListener { _ in
            expectation.fulfill()
        }

        string.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_nestedViewModel_property_withReference_afterAddingSingleListener_withoutRemove_onDeinit_doesNotCallListener() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        let nestedInstance = instance.viewModelInstanceProperty(fromPath: "Nested")!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)
        var string: RiveDataBindingViewModel.Instance.StringProperty? = nestedInstance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        expectation.isInverted = true
        string?.addListener { _ in
            expectation.fulfill()
        }
        string = nil

        string?.value = "Listener"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_nestedViewModel_property_afterAddingSingleListener_whenBound_andParentReleased_callsListener() throws {
        var instance: RiveDataBindingViewModel.Instance? = file.viewModelNamed("Test")!.createDefaultInstance()!
        let nestedInstance = instance!.viewModelInstanceProperty(fromPath: "Nested")!
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance!)
        let string = nestedInstance.stringProperty(fromPath: "String")!

        let expectation = expectation(description: "Updated")
        string.addListener { _ in
            expectation.fulfill()
        }

        instance = nil
        stateMachine.bind(viewModelInstance: nestedInstance)

        string.value = "Listener"
        stateMachine.advance(by: 0)
        nestedInstance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }

    func test_instance_property_whenBoundToTwoStateMachines_ifNoAdditionalChanges_callsListenerOnce() throws {
        let instance = file.viewModelNamed("Test")!.createDefaultInstance()!
        
        let artboard = try file.artboard()
        let stateMachine = try artboard.stateMachine(from: 0)
        stateMachine.bind(viewModelInstance: instance)

        let file2 = try! RiveFile(testfileName: "data_binding_test")
        let artboard2 = try file2.artboard()
        let stateMachine2 = try artboard2.stateMachine(from: 0)
        stateMachine2.bind(viewModelInstance: instance)

        let expectation = expectation(description: "listener called")
        expectation.expectedFulfillmentCount = 1

        let string = instance.stringProperty(fromPath: "String")!
        string.addListener { value in
            XCTAssertEqual(value, "Foo")
            expectation.fulfill()
        }

        string.value = "Foo"
        stateMachine.advance(by: 0)
        instance.updateListeners()

        stateMachine2.advance(by: 0)
        instance.updateListeners()

        wait(for: [expectation], timeout: 1)
    }
}

// MARK: - Helpers

fileprivate struct Color: Equatable {
    let a: Int
    let r: Int
    let g: Int
    let b: Int

    init(_ color: UIColor) {
        var a: CGFloat = 0
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.a = Int(a * 255)
        self.r = Int(r * 255)
        self.g = Int(g * 255)
        self.b = Int(b * 255)
    }
}
