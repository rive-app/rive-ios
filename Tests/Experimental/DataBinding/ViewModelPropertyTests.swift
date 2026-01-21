//
//  ViewModelPropertyTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 12/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class ViewModelPropertyTests: XCTestCase {
    
    // MARK: - Direct Initialization Tests
    
    func test_init_withValidParameters_createsProperty() {
        let property = ViewModelProperty(
            type: .string,
            name: "TestProperty",
            metaData: "Some metadata"
        )
        
        XCTAssertEqual(property.type, .string)
        XCTAssertEqual(property.name, "TestProperty")
        XCTAssertEqual(property.metaData, "Some metadata")
    }
    
    func test_init_withEmptyMetaData_createsProperty() {
        let property = ViewModelProperty(
            type: .number,
            name: "NumberProperty",
            metaData: ""
        )
        
        XCTAssertEqual(property.type, .number)
        XCTAssertEqual(property.name, "NumberProperty")
        XCTAssertEqual(property.metaData, "")
    }
    
    // MARK: - Dictionary Initialization Tests
    
    func test_initFromDictionary_withValidDictionary_createsProperty() throws {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.string.rawValue),
            "name": "TestProperty",
            "metaData": "Some metadata"
        ]
        
        let property = try ViewModelProperty(from: dictionary)
        
        XCTAssertEqual(property.type, .string)
        XCTAssertEqual(property.name, "TestProperty")
        XCTAssertEqual(property.metaData, "Some metadata")
    }
    
    func test_initFromDictionary_withEmptyMetaData_createsProperty() throws {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.boolean.rawValue),
            "name": "BooleanProperty",
            "metaData": ""
        ]
        
        let property = try ViewModelProperty(from: dictionary)
        
        XCTAssertEqual(property.type, .boolean)
        XCTAssertEqual(property.name, "BooleanProperty")
        XCTAssertEqual(property.metaData, "")
    }
    
    func test_initFromDictionary_withMissingMetaData_usesEmptyString() throws {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.color.rawValue),
            "name": "ColorProperty"
        ]
        
        let property = try ViewModelProperty(from: dictionary)
        
        XCTAssertEqual(property.type, .color)
        XCTAssertEqual(property.name, "ColorProperty")
        XCTAssertEqual(property.metaData, "")
    }
    
    func test_initFromDictionary_withAllPropertyTypes_createsCorrectProperties() throws {
        let types: [(RiveViewModelInstanceDataType, String, ViewModelProperty.DataType)] = [
            (.none, "None", .none),
            (.string, "String", .string),
            (.number, "Number", .number),
            (.boolean, "Boolean", .boolean),
            (.color, "Color", .color),
            (.list, "List", .list),
            (.enum, "Enum", .enum),
            (.trigger, "Trigger", .trigger),
            (.viewModel, "ViewModel", .viewModel),
            (.integer, "Integer", .integer),
            (.symbolListIndex, "SymbolListIndex", .symbolListIndex),
            (.assetImage, "AssetImage", .assetImage),
            (.artboard, "Artboard", .artboard),
            (.input, "Input", .input),
            (.any, "Any", .any)
        ]
        
        for (origin, name, type) in types {
            let dictionary: [String: Any] = [
                "type": NSNumber(value: origin.rawValue),
                "name": name,
                "metaData": "metadata for \(name)"
            ]
            
            let property = try ViewModelProperty(from: dictionary)
            XCTAssertEqual(property.type, type, "Failed for type: \(name)")
            XCTAssertEqual(property.name, name)
            XCTAssertEqual(property.metaData, "metadata for \(name)")
        }
    }
    
    // MARK: - Error Cases
    
    func test_initFromDictionary_withMissingType_throwsError() {
        let dictionary: [String: Any] = [
            "name": "TestProperty",
            "metaData": "Some metadata"
        ]
        
        XCTAssertThrowsError(try ViewModelProperty(from: dictionary)) { error in
            XCTAssertEqual(error as? ViewModelPropertyError, .missingType)
        }
    }
    
    func test_initFromDictionary_withMissingName_throwsError() {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.string.rawValue),
            "metaData": "Some metadata"
        ]
        
        XCTAssertThrowsError(try ViewModelProperty(from: dictionary)) { error in
            XCTAssertEqual(error as? ViewModelPropertyError, .missingName)
        }
    }
    
    func test_initFromDictionary_withInvalidType_throwsError() {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: 999), // Invalid enum value
            "name": "TestProperty",
            "metaData": "Some metadata"
        ]
        
        XCTAssertThrowsError(try ViewModelProperty(from: dictionary)) { error in
            guard let propertyError = error as? ViewModelPropertyError else {
                XCTFail("Expected ViewModelPropertyError, got \(error)")
                return
            }
            guard case .invalidType(let typeValue) = propertyError else {
                XCTFail("Expected invalidType error, got \(propertyError)")
                return
            }
            XCTAssertEqual(typeValue, 999)
        }
    }
    
    func test_initFromDictionary_withWrongTypeForType_throwsError() {
        let dictionary: [String: Any] = [
            "type": "not a number", // Wrong type
            "name": "TestProperty",
            "metaData": "Some metadata"
        ]
        
        XCTAssertThrowsError(try ViewModelProperty(from: dictionary)) { error in
            XCTAssertEqual(error as? ViewModelPropertyError, .missingType)
        }
    }
    
    func test_initFromDictionary_withWrongTypeForName_throwsError() {
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.string.rawValue),
            "name": 123, // Wrong type
            "metaData": "Some metadata"
        ]
        
        XCTAssertThrowsError(try ViewModelProperty(from: dictionary)) { error in
            XCTAssertEqual(error as? ViewModelPropertyError, .missingName)
        }
    }
    
    // MARK: - Integration Tests
    
    func test_initFromDictionary_matchesDirectInit() throws {
        let directProperty = ViewModelProperty(
            type: .enum,
            name: "EnumProperty",
            metaData: "enum metadata"
        )
        
        let dictionary: [String: Any] = [
            "type": NSNumber(value: RiveViewModelInstanceDataType.enum.rawValue),
            "name": "EnumProperty",
            "metaData": "enum metadata"
        ]
        
        let dictionaryProperty = try ViewModelProperty(from: dictionary)
        
        XCTAssertEqual(directProperty.type, dictionaryProperty.type)
        XCTAssertEqual(directProperty.name, dictionaryProperty.name)
        XCTAssertEqual(directProperty.metaData, dictionaryProperty.metaData)
    }
    
    // MARK: - DataType Conversion Tests
    
    func test_dataType_initWithObjcValue_withAllValidTypes_returnsCorrectDataType() {
        let testCases: [(RiveViewModelInstanceDataType, ViewModelProperty.DataType)] = [
            (.none, .none),
            (.string, .string),
            (.number, .number),
            (.boolean, .boolean),
            (.color, .color),
            (.list, .list),
            (.enum, .enum),
            (.trigger, .trigger),
            (.viewModel, .viewModel),
            (.integer, .integer),
            (.symbolListIndex, .symbolListIndex),
            (.assetImage, .assetImage),
            (.artboard, .artboard),
            (.input, .input),
            (.any, .any)
        ]
        
        for (objcType, expectedDataType) in testCases {
            guard let dataType = ViewModelProperty.DataType(objcValue: objcType) else {
                XCTFail("Failed to create DataType from \(objcType)")
                continue
            }
            XCTAssertEqual(dataType, expectedDataType, "Failed for objcType: \(objcType)")
        }
    }
    
    func test_dataType_initWithObjcValue_withUnknownValue_returnsNil() {
        // Create an invalid enum value that doesn't exist
        // Since NS_ENUM uses NSInteger, we can use a value that's beyond the known cases
        // We need to use unsafeBitCast or a similar approach since rawValue initializer might return nil
        let invalidRawValue = RiveViewModelInstanceDataType.any.rawValue + 100
        // Use unsafeBitCast to create an enum value that doesn't exist in the known cases
        // This simulates what would happen if a new enum case was added in the future
        let invalidObjcType = unsafeBitCast(invalidRawValue, to: RiveViewModelInstanceDataType.self)
        
        let dataType = ViewModelProperty.DataType(objcValue: invalidObjcType)
        XCTAssertNil(dataType, "Should return nil for unknown objcValue")
    }
    
    func test_dataType_objcValue_withAllDataTypes_returnsCorrectObjcType() {
        let testCases: [(ViewModelProperty.DataType, RiveViewModelInstanceDataType)] = [
            (.none, .none),
            (.string, .string),
            (.number, .number),
            (.boolean, .boolean),
            (.color, .color),
            (.list, .list),
            (.enum, .enum),
            (.trigger, .trigger),
            (.viewModel, .viewModel),
            (.integer, .integer),
            (.symbolListIndex, .symbolListIndex),
            (.assetImage, .assetImage),
            (.artboard, .artboard),
            (.input, .input),
            (.any, .any)
        ]
        
        for (dataType, expectedObjcType) in testCases {
            let objcType = dataType.objcValue
            XCTAssertEqual(objcType, expectedObjcType, "Failed for dataType: \(dataType)")
        }
    }
}

