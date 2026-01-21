//
//  ViewModelInstanceTests.swift
//  RiveRuntimeTests
//
//  Created by David Skuza on 11/25/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import XCTest
@_spi(RiveExperimental) @testable import RiveRuntime

class ViewModelInstanceTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    @MainActor
    func makeViewModelInstance(
        mockCommandQueue: MockCommandQueue,
        captureObserver: ((ViewModelInstanceListener?) -> Void)? = nil
    ) -> ViewModelInstance {
        let (file, _, _, _) = File.mock(fileHandle: 123, commandQueue: mockCommandQueue)
        
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        mockCommandQueue.stubCreateBlankViewModelInstance { _, _, observer, _ in
            captureObserver?(observer)
            return 99
        }
        
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let viewModelInstance = ViewModelInstance(
            for: artboard,
            from: file,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        return viewModelInstance
    }
    
    @MainActor
    func test_init_withValidArtboardAndFile_createsInstance() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        XCTAssertNotNil(viewModelInstance)
        XCTAssertEqual(viewModelInstance.viewModelInstanceHandle, 99)
    }
    
    // MARK: - String
    
    @MainActor
    func test_value_withStringProperty_returnsStringValue() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceString { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "test value")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = StringProperty(path: "test.path")
        let value = try await viewModelInstance.value(of: property)

        XCTAssertEqual(value, "test value")
    }
    
    @MainActor
    func test_setValue_withStringProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = StringProperty(path: "test.property.path")
        let testValue = "test string value"
        
        viewModelInstance.setValue(of: property, to: testValue)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceStringCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceStringCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.property.path")
        XCTAssertEqual(call.value, "test string value")
    }
    
    @MainActor
    func test_value_withStringProperty_returnsTypeMismatchError() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceString { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(numberValue: NSNumber(value: 42))
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = StringProperty(path: "test.path")
        
        do {
            _ = try await viewModelInstance.value(of: property)
            XCTFail("Expected ViewModelInstanceError.valueMismatch to be thrown")
        } catch ViewModelInstanceError.valueMismatch {
            // Expected error
        } catch {
            XCTFail("Expected ViewModelInstanceError.valueMismatch, got \(type(of: error)): \(error)")
        }
    }
    
    @MainActor
    func test_valueStream_withStringProperty_receivesUpdates() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = StringProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.path")
        XCTAssertEqual(subscribeCall.type, .string)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let task = Task {
            var values: [String] = []
            for try await value in stream {
                values.append(value)
                break
            }
            return values
        }
        
        let firstValue = MockRiveViewModelInstanceData(stringValue: "first value")
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstValue)
        
        let values = try await task.value
        
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0], "first value")
    }
    
    @MainActor
    func test_valueStream_withStringProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = StringProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.path")
        XCTAssertEqual(unsubscribeCall.type, .string)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - Number
    
    @MainActor
    func test_value_withNumberProperty_returnsFloatValue() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceNumber { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(numberValue: NSNumber(value: 42.5))
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = NumberProperty(path: "test.path")
        let value = try await viewModelInstance.value(of: property)

        XCTAssertEqual(value, 42.5, accuracy: 0.001)
    }
    
    @MainActor
    func test_setValue_withNumberProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = NumberProperty(path: "test.property.path")
        let testValue: Float = 42.5
        
        viewModelInstance.setValue(of: property, to: testValue)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceNumberCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceNumberCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.property.path")
        XCTAssertEqual(call.value, 42.5, accuracy: 0.001)
    }
    
    @MainActor
    func test_value_withNumberProperty_returnsTypeMismatchError() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceNumber { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "not a number")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = NumberProperty(path: "test.path")
        
        do {
            _ = try await viewModelInstance.value(of: property)
            XCTFail("Expected ViewModelInstanceError.valueMismatch to be thrown")
        } catch let error as ViewModelInstanceError {
            guard case .valueMismatch(let expected, let actual) = error else {
                XCTFail("Expected valueMismatch error, got \(error)")
                return
            }
            XCTAssertTrue(expected.contains("Float"))
            XCTAssertTrue(actual.contains("String"))
        } catch {
            XCTFail("Expected ViewModelInstanceError.valueMismatch, got \(type(of: error)): \(error)")
        }
    }
    
    @MainActor
    func test_valueStream_withNumberProperty_receivesUpdates() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = NumberProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.path")
        XCTAssertEqual(subscribeCall.type, .number)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let task = Task {
            var values: [Float] = []
            for try await value in stream {
                values.append(value)
                break
            }
            return values
        }
        
        let firstValue = MockRiveViewModelInstanceData(numberValue: NSNumber(value: 42.5))
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstValue)
        
        let values = try await task.value
        
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0], 42.5, accuracy: 0.001)
    }
    
    @MainActor
    func test_valueStream_withNumberProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = NumberProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.path")
        XCTAssertEqual(unsubscribeCall.type, .number)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - Bool
    
    @MainActor
    func test_value_withBoolProperty_returnsBoolValue() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceBool { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(boolValue: NSNumber(value: true))
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = BoolProperty(path: "test.path")
        let value = try await viewModelInstance.value(of: property)

        XCTAssertEqual(value, true)
    }
    
    @MainActor
    func test_setValue_withBoolProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = BoolProperty(path: "test.property.path")
        let testValue = true
        
        viewModelInstance.setValue(of: property, to: testValue)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceBoolCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceBoolCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.property.path")
        XCTAssertEqual(call.value, true)
    }
    
    @MainActor
    func test_value_withBoolProperty_returnsTypeMismatchError() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceBool { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "not a bool")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = BoolProperty(path: "test.path")
        
        do {
            _ = try await viewModelInstance.value(of: property)
            XCTFail("Expected ViewModelInstanceError.valueMismatch to be thrown")
        } catch let error as ViewModelInstanceError {
            guard case .valueMismatch(let expected, let actual) = error else {
                XCTFail("Expected valueMismatch error, got \(error)")
                return
            }
            XCTAssertTrue(expected.contains("Bool"))
            XCTAssertTrue(actual.contains("String"))
        } catch {
            XCTFail("Expected ViewModelInstanceError.valueMismatch, got \(type(of: error)): \(error)")
        }
    }
    
    @MainActor
    func test_valueStream_withBoolProperty_receivesUpdates() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = BoolProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.path")
        XCTAssertEqual(subscribeCall.type, .boolean)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let task = Task {
            var values: [Bool] = []
            for try await value in stream {
                values.append(value)
                break
            }
            return values
        }
        
        let firstValue = MockRiveViewModelInstanceData(boolValue: NSNumber(value: true))
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstValue)
        
        let values = try await task.value
        
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0], true)
    }
    
    @MainActor
    func test_valueStream_withBoolProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = BoolProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.path")
        XCTAssertEqual(unsubscribeCall.type, .boolean)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - Color
    
    @MainActor
    func test_value_withColorProperty_returnsColorValue() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        // ARGB: 0xFF00FF00 (alpha=255, red=0, green=255, blue=0) = bright green
        let argbValue: UInt32 = 0xFF00FF00
        mockCommandQueue.stubRequestViewModelInstanceColor { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(colorValue: NSNumber(value: argbValue))
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = ColorProperty(path: "test.path")
        let value = try await viewModelInstance.value(of: property)

        XCTAssertEqual(value.alpha, 255)
        XCTAssertEqual(value.red, 0)
        XCTAssertEqual(value.green, 255)
        XCTAssertEqual(value.blue, 0)
    }
    
    @MainActor
    func test_setValue_withColorProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = ColorProperty(path: "test.property.path")
        // ARGB: 0xFF00FF00 (alpha=255, red=0, green=255, blue=0) = bright green
        let testValue = Color(red: 0, green: 255, blue: 0, alpha: 255)
        
        viewModelInstance.setValue(of: property, to: testValue)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceColorCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceColorCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.property.path")
        XCTAssertEqual(call.value, 0xFF00FF00) // ARGB value
    }
    
    @MainActor
    func test_value_withColorProperty_returnsTypeMismatchError() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceColor { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "not a color")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = ColorProperty(path: "test.path")
        
        do {
            _ = try await viewModelInstance.value(of: property)
            XCTFail("Expected ViewModelInstanceError.valueMismatch to be thrown")
        } catch let error as ViewModelInstanceError {
            guard case .valueMismatch(let expected, let actual) = error else {
                XCTFail("Expected valueMismatch error, got \(error)")
                return
            }
            XCTAssertTrue(expected.contains("Color"))
            XCTAssertTrue(actual.contains("String"))
        } catch {
            XCTFail("Expected ViewModelInstanceError.valueMismatch, got \(type(of: error)): \(error)")
        }
    }
    
    @MainActor
    func test_valueStream_withColorProperty_receivesUpdates() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = ColorProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.path")
        XCTAssertEqual(subscribeCall.type, .color)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let task = Task {
            var values: [Color] = []
            for try await value in stream {
                values.append(value)
                break
            }
            return values
        }
        
        // ARGB: 0xFF00FF00 (alpha=255, red=0, green=255, blue=0) = bright green
        let argbValue: UInt32 = 0xFF00FF00
        let firstValue = MockRiveViewModelInstanceData(colorValue: NSNumber(value: argbValue))
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstValue)
        
        let values = try await task.value
        
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0].alpha, 255)
        XCTAssertEqual(values[0].red, 0)
        XCTAssertEqual(values[0].green, 255)
        XCTAssertEqual(values[0].blue, 0)
    }
    
    @MainActor
    func test_valueStream_withColorProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = ColorProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.path")
        XCTAssertEqual(unsubscribeCall.type, .color)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - Enum
    
    @MainActor
    func test_value_withEnumProperty_returnsStringValue() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceEnum { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "enumValue")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = EnumProperty(path: "test.path")
        let value = try await viewModelInstance.value(of: property)

        XCTAssertEqual(value, "enumValue")
    }
    
    @MainActor
    func test_value_withEnumProperty_returnsTypeMismatchError() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        mockCommandQueue.stubRequestViewModelInstanceEnum { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(numberValue: NSNumber(value: 42))
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let property = EnumProperty(path: "test.path")
        
        do {
            _ = try await viewModelInstance.value(of: property)
            XCTFail("Expected ViewModelInstanceError.valueMismatch to be thrown")
        } catch ViewModelInstanceError.valueMismatch {
            // Expected error
        } catch {
            XCTFail("Expected ViewModelInstanceError.valueMismatch, got \(type(of: error)): \(error)")
        }
    }
    
    @MainActor
    func test_valueStream_withEnumProperty_receivesUpdates() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = EnumProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.path")
        XCTAssertEqual(subscribeCall.type, .enum)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let task = Task {
            var values: [String] = []
            for try await value in stream {
                values.append(value)
                break
            }
            return values
        }
        
        let firstValue = MockRiveViewModelInstanceData(stringValue: "enumValue")
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstValue)
        
        let values = try await task.value
        
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0], "enumValue")
    }
    
    @MainActor
    func test_valueStream_withEnumProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = EnumProperty(path: "test.path")
        let stream = viewModelInstance.valueStream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.path")
        XCTAssertEqual(unsubscribeCall.type, .enum)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - Image
    
    @MainActor
    func test_setValue_withImageProperty_sendsCorrectValuesToCommandQueue() async throws {
        let mockCommandQueue = MockCommandQueue()
        let imageService = ImageService(dependencies: .init(commandQueue: mockCommandQueue))
        let renderImageDependencies = Image.Dependencies(imageService: imageService)
        
        let testData = Data([0x89, 0x50, 0x4E, 0x47])
        let expectedRenderImageHandle: UInt64 = 42
        
        let decodeExpectation = expectation(description: "decodeImage called")
        mockCommandQueue.stubDecodeImage { data, listener, requestID in
            XCTAssertEqual(data, testData)
            decodeExpectation.fulfill()
            listener.onRenderImageDecoded(expectedRenderImageHandle, requestID: requestID)
            return expectedRenderImageHandle
        }
        
        let renderImage = try await Image(data: testData, dependencies: renderImageDependencies)
        await fulfillment(of: [decodeExpectation], timeout: 1)
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        let property = ImageProperty(path: "test.image.property.path")
        
        viewModelInstance.setValue(of: property, to: renderImage)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceImageCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceImageCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.image.property.path")
        XCTAssertEqual(call.value, expectedRenderImageHandle)
    }
    
    // MARK: - Artboard
    
    @MainActor
    func test_setValue_withArtboardProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let expectedArtboardHandle: UInt64 = 42
        let artboard = Artboard(
            dependencies: .init(
                artboardService: .init(
                    dependencies: .init(
                        commandQueue: mockCommandQueue
                    )
                )
            ),
            artboardHandle: expectedArtboardHandle
        )
        let property = ArtboardProperty(path: "test.artboard.property.path")
        
        viewModelInstance.setValue(of: property, to: artboard)

        XCTAssertEqual(mockCommandQueue.setViewModelInstanceArtboardCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceArtboardCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.artboard.property.path")
        XCTAssertEqual(call.value, expectedArtboardHandle)
    }
    
    // MARK: - Trigger
    
    @MainActor
    func test_fire_withTriggerProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let trigger = TriggerProperty(path: "test.trigger.path")
        
        viewModelInstance.fire(trigger: trigger)
        
        XCTAssertEqual(mockCommandQueue.fireViewModelTriggerCalls.count, 1)
        let call = mockCommandQueue.fireViewModelTriggerCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99) // The handle returned by the stub
        XCTAssertEqual(call.path, "test.trigger.path")
    }
    
    @MainActor
    func test_stream_withTriggerProperty_receivesEvents() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = TriggerProperty(path: "test.trigger.path")
        let stream = viewModelInstance.stream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(subscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(subscribeCall.path, "test.trigger.path")
        XCTAssertEqual(subscribeCall.type, .trigger)
        
        let observer = mockCommandQueue.getObserver(for: 99)
        let requestID = subscribeCall.requestID
        
        let eventsReceivedExpectation = expectation(description: "Two trigger events received")
        
        let task = Task {
            var eventCount = 0
            for try await _ in stream {
                eventCount += 1
                if eventCount >= 2 {
                    eventsReceivedExpectation.fulfill()
                    break
                }
            }
            return eventCount
        }
        
        let firstEvent = MockRiveViewModelInstanceData(type: .trigger)
        observer?.onViewModelDataReceived(99, requestID: requestID, data: firstEvent)
        
        let secondEvent = MockRiveViewModelInstanceData(type: .trigger)
        observer?.onViewModelDataReceived(99, requestID: requestID, data: secondEvent)
        
        await fulfillment(of: [eventsReceivedExpectation], timeout: 1.0)
        
        let eventCount = try await task.value
        
        XCTAssertEqual(eventCount, 2)
    }
    
    @MainActor
    func test_stream_withTriggerProperty_unsubscribesOnTermination() async throws {
        let mockCommandQueue = MockCommandQueue()
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let property = TriggerProperty(path: "test.trigger.path")
        let stream = viewModelInstance.stream(of: property)
        
        XCTAssertEqual(mockCommandQueue.subscribeToViewModelPropertyCalls.count, 1)
        let subscribeCall = mockCommandQueue.subscribeToViewModelPropertyCalls[0]
        let requestID = subscribeCall.requestID
        
        let unsubscribeExpectation = expectation(description: "Unsubscribe called")
        
        mockCommandQueue.stubUnsubscribeToViewModelProperty { _, _, _, _ in
            unsubscribeExpectation.fulfill()
        }
        
        let task = Task {
            for try await _ in stream {
            }
        }
        
        task.cancel()
        
        await fulfillment(of: [unsubscribeExpectation], timeout: 1.0)

        XCTAssertEqual(mockCommandQueue.unsubscribeToViewModelPropertyCalls.count, 1)
        let unsubscribeCall = mockCommandQueue.unsubscribeToViewModelPropertyCalls[0]
        XCTAssertEqual(unsubscribeCall.viewModelInstanceHandle, 99)
        XCTAssertEqual(unsubscribeCall.path, "test.trigger.path")
        XCTAssertEqual(unsubscribeCall.type, .trigger)
        XCTAssertEqual(unsubscribeCall.requestID, requestID)
    }
    
    // MARK: - ViewModelInstanceProperty
    
    @MainActor
    func test_value_withViewModelInstanceProperty_returnsNestedViewModelInstance() async throws {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let expectedNestedHandle: UInt64 = 200
        var capturedObserver: ViewModelInstanceListener?
        
        mockCommandQueue.stubReferenceNestedViewModelInstance { instanceHandle, path, observer, requestID in
            capturedObserver = observer
            return expectedNestedHandle
        }
        
        let property = ViewModelInstanceProperty(path: "nested.property.path")
        let nestedInstance = viewModelInstance.value(of: property)
        
        // Verify the nested instance was created correctly
        XCTAssertEqual(nestedInstance.viewModelInstanceHandle, expectedNestedHandle)
        
        // Verify the nested instance can get string values (ensures service is set up correctly)
        let getProperty = StringProperty(path: "test.get.path")
        mockCommandQueue.stubRequestViewModelInstanceString { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "retrieved value")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let retrievedValue = try await nestedInstance.value(of: getProperty)
        XCTAssertEqual(retrievedValue, "retrieved value")
        
        // Verify the nested instance can set string values (ensures service is set up correctly)
        let setProperty = StringProperty(path: "test.set.path")
        nestedInstance.setValue(of: setProperty, to: "set value")
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceStringCalls.count, 1)
        let setCall = mockCommandQueue.setViewModelInstanceStringCalls[0]
        XCTAssertEqual(setCall.viewModelInstanceHandle, expectedNestedHandle)
        XCTAssertEqual(setCall.path, "test.set.path")
        XCTAssertEqual(setCall.value, "set value")
    }
    
    @MainActor
    func test_setValue_withViewModelInstanceProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let nestedInstanceHandle: UInt64 = 200
        let nestedInstance = ViewModelInstance(
            handle: nestedInstanceHandle,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        let property = ViewModelInstanceProperty(path: "test.nested.property.path")
        
        viewModelInstance.setValue(of: property, to: nestedInstance)
        
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceNestedViewModelCalls.count, 1)
        let call = mockCommandQueue.setViewModelInstanceNestedViewModelCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.nested.property.path")
        XCTAssertEqual(call.value, nestedInstanceHandle)
    }
    
    // MARK: - ListProperty
    
    @MainActor
    func test_size_withListProperty_returnsListSize() async throws {
        let mockCommandQueue = MockCommandQueue()
        var capturedObserver: ViewModelInstanceListener?
        
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue) { observer in
            capturedObserver = observer
        }
        
        let expectedSize = 5
        mockCommandQueue.stubRequestViewModelInstanceListSize { instanceHandle, path, requestID in
            capturedObserver?.onViewModelListSizeReceived(instanceHandle, requestID: requestID, path: path, size: expectedSize)
        }
        
        let property = ListProperty(path: "test.list.path")
        let size = try await viewModelInstance.size(of: property)
        
        XCTAssertEqual(size, expectedSize)
    }
    
    @MainActor
    func test_value_withListProperty_returnsNestedViewModelInstance() async throws {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        let property = ListProperty(path: "list")
        var capturedObserver: ViewModelInstanceListener?
        
        // Test retrieving list item at index 0
        let expectedHandle0: UInt64 = 200
        mockCommandQueue.stubReferenceListViewModelInstance { instanceHandle, path, index, observer, requestID in
            capturedObserver = observer
            XCTAssertEqual(instanceHandle, 99) // The handle from makeViewModelInstance
            XCTAssertEqual(path, "list") // The list property path
            XCTAssertEqual(index, 0)
            return expectedHandle0
        }
        
        let listItem0 = viewModelInstance.value(of: property, at: 0)
        XCTAssertEqual(listItem0.viewModelInstanceHandle, expectedHandle0)
        XCTAssertEqual(mockCommandQueue.referenceListViewModelInstanceCalls.count, 1)
        let call0 = mockCommandQueue.referenceListViewModelInstanceCalls[0]
        XCTAssertEqual(call0.viewModelInstanceHandle, 99)
        XCTAssertEqual(call0.path, "list")
        XCTAssertEqual(call0.index, 0)
        
        // Test retrieving list item at index 2
        let expectedHandle2: UInt64 = 201
        mockCommandQueue.stubReferenceListViewModelInstance { instanceHandle, path, index, observer, requestID in
            capturedObserver = observer
            XCTAssertEqual(instanceHandle, 99)
            XCTAssertEqual(path, "list") // The list property path
            XCTAssertEqual(index, 2)
            return expectedHandle2
        }
        
        let listItem2 = viewModelInstance.value(of: property, at: 2)
        XCTAssertEqual(listItem2.viewModelInstanceHandle, expectedHandle2)
        XCTAssertEqual(mockCommandQueue.referenceListViewModelInstanceCalls.count, 2)
        let call2 = mockCommandQueue.referenceListViewModelInstanceCalls[1]
        XCTAssertEqual(call2.viewModelInstanceHandle, 99)
        XCTAssertEqual(call2.path, "list")
        XCTAssertEqual(call2.index, 2)
        
        // Test that we can interact with the list item instance
        let testProperty = StringProperty(path: "string")
        mockCommandQueue.stubRequestViewModelInstanceString { instanceHandle, path, requestID in
            let mockData = MockRiveViewModelInstanceData(stringValue: "retrieved value")
            capturedObserver?.onViewModelDataReceived(instanceHandle, requestID: requestID, data: mockData)
        }
        
        let retrievedValue = try await listItem2.value(of: testProperty)
        XCTAssertEqual(retrievedValue, "retrieved value")
        
        listItem2.setValue(of: testProperty, to: "set value")
        XCTAssertEqual(mockCommandQueue.setViewModelInstanceStringCalls.count, 1)
        let setCall = mockCommandQueue.setViewModelInstanceStringCalls[0]
        XCTAssertEqual(setCall.viewModelInstanceHandle, expectedHandle2)
        XCTAssertEqual(setCall.path, "string")
        XCTAssertEqual(setCall.value, "set value")
    }
    
    @MainActor
    func test_appendInstance_withListProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let instanceToAppendHandle: UInt64 = 200
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let instanceToAppend = ViewModelInstance(
            handle: instanceToAppendHandle,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        let listProperty = ListProperty(path: "test.list.path")
        
        viewModelInstance.appendInstance(instanceToAppend, to: listProperty)
        
        XCTAssertEqual(mockCommandQueue.appendViewModelInstanceListViewModelCalls.count, 1)
        let call = mockCommandQueue.appendViewModelInstanceListViewModelCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.list.path")
        XCTAssertEqual(call.value, instanceToAppendHandle)
    }
    
    @MainActor
    func test_insertInstance_withListProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let instanceToInsertHandle: UInt64 = 200
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let instanceToInsert = ViewModelInstance(
            handle: instanceToInsertHandle,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        let listProperty = ListProperty(path: "test.list.path")
        let insertIndex: Int32 = 2
        
        viewModelInstance.insertInstance(instanceToInsert, to: listProperty, at: insertIndex)
        
        XCTAssertEqual(mockCommandQueue.insertViewModelInstanceListViewModelCalls.count, 1)
        let call = mockCommandQueue.insertViewModelInstanceListViewModelCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.list.path")
        XCTAssertEqual(call.value, instanceToInsertHandle)
        XCTAssertEqual(call.index, insertIndex)
    }
    
    @MainActor
    func test_removeInstanceAtIndex_withListProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let listProperty = ListProperty(path: "test.list.path")
        let removeIndex: Int32 = 2
        
        viewModelInstance.removeInstance(at: removeIndex, from: listProperty)
        
        XCTAssertEqual(mockCommandQueue.removeViewModelInstanceListViewModelAtIndexCalls.count, 1)
        let call = mockCommandQueue.removeViewModelInstanceListViewModelAtIndexCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.list.path")
        XCTAssertEqual(call.index, removeIndex)
        XCTAssertEqual(call.value, 0)
    }
    
    @MainActor
    func test_removeInstanceByValue_withListProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let instanceToRemoveHandle: UInt64 = 200
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let instanceToRemove = ViewModelInstance(
            handle: instanceToRemoveHandle,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        let listProperty = ListProperty(path: "test.list.path")
        
        viewModelInstance.removeInstance(instanceToRemove, from: listProperty)
        
        XCTAssertEqual(mockCommandQueue.removeViewModelInstanceListViewModelByValueCalls.count, 1)
        let call = mockCommandQueue.removeViewModelInstanceListViewModelByValueCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.list.path")
        XCTAssertEqual(call.value, instanceToRemoveHandle)
    }
    
    @MainActor
    func test_swapInstances_withListProperty_sendsCorrectValuesToCommandQueue() {
        let mockCommandQueue = MockCommandQueue()
        let viewModelInstance = makeViewModelInstance(mockCommandQueue: mockCommandQueue)
        
        let listProperty = ListProperty(path: "test.list.path")
        let atIndex: Int32 = 0
        let withIndex: Int32 = 2
        
        viewModelInstance.swapInstance(atIndex: atIndex, withIndex: withIndex, in: listProperty)
        
        XCTAssertEqual(mockCommandQueue.swapViewModelInstanceListValuesCalls.count, 1)
        let call = mockCommandQueue.swapViewModelInstanceListValuesCalls[0]
        XCTAssertEqual(call.viewModelInstanceHandle, 99)
        XCTAssertEqual(call.path, "test.list.path")
        XCTAssertEqual(call.atIndex, atIndex)
        XCTAssertEqual(call.withIndex, withIndex)
    }
    
    // MARK: - ViewModelInstanceSource Tests
    
    @MainActor
    func test_init_withNamedInstanceSourceForArtboard_createsNamedInstance() {
        let mockCommandQueue = MockCommandQueue()
        let (file, _, _, _) = File.mock(fileHandle: 123, commandQueue: mockCommandQueue)
        
        let artboardService = ArtboardService(dependencies: .init(commandQueue: mockCommandQueue))
        let artboardDependencies = Artboard.Dependencies(
            artboardService: artboardService
        )
        let artboard = Artboard(dependencies: artboardDependencies, artboardHandle: 42)
        
        var capturedInstanceName: String?
        var capturedArtboardHandle: UInt64 = 0
        var capturedFileHandle: UInt64 = 0
        var capturedObserver: ViewModelInstanceListener?
        
        mockCommandQueue.stubCreateViewModelInstanceNamedForArtboard { instanceName, artboardHandle, fileHandle, observer, requestID in
            capturedInstanceName = instanceName
            capturedArtboardHandle = artboardHandle
            capturedFileHandle = fileHandle
            capturedObserver = observer
            return 200
        }
        
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let viewModelInstance = ViewModelInstance(
            source: .name("TestInstance", from: .artboardDefault(artboard)),
            from: file,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        XCTAssertNotNil(viewModelInstance)
        XCTAssertEqual(viewModelInstance.viewModelInstanceHandle, 200)
        XCTAssertEqual(capturedInstanceName, "TestInstance")
        XCTAssertEqual(capturedArtboardHandle, 42)
        XCTAssertEqual(capturedFileHandle, 123)
        XCTAssertNotNil(capturedObserver)
    }
    
    @MainActor
    func test_init_withNamedInstanceSourceForViewModelName_createsNamedInstance() {
        let mockCommandQueue = MockCommandQueue()
        let (file, _, _, _) = File.mock(fileHandle: 456, commandQueue: mockCommandQueue)
        
        var capturedInstanceName: String?
        var capturedViewModelName: String?
        var capturedFileHandle: UInt64 = 0
        var capturedObserver: ViewModelInstanceListener?
        
        mockCommandQueue.stubCreateViewModelInstanceNamed { instanceName, viewModelName, fileHandle, observer, requestID in
            capturedInstanceName = instanceName
            capturedViewModelName = viewModelName
            capturedFileHandle = fileHandle
            capturedObserver = observer
            return 201
        }
        
        let viewModelInstanceService = ViewModelInstanceService(dependencies: .init(commandQueue: mockCommandQueue))
        let viewModelInstance = ViewModelInstance(
            source: .name("MyInstance", from: .name("MyViewModel")),
            from: file,
            dependencies: .init(
                viewModelInstanceService: viewModelInstanceService
            )
        )
        
        XCTAssertNotNil(viewModelInstance)
        XCTAssertEqual(viewModelInstance.viewModelInstanceHandle, 201)
        XCTAssertEqual(capturedInstanceName, "MyInstance")
        XCTAssertEqual(capturedViewModelName, "MyViewModel")
        XCTAssertEqual(capturedFileHandle, 456)
        XCTAssertNotNil(capturedObserver)
    }
}
