//
//  ViewModelInstance.swift
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation

/// Specifies the source view model to use when creating a view model instance.
@_spi(RiveExperimental)
public enum ViewModelSource {
    /// Uses the default view model associated with the specified artboard.
    case artboardDefault(Artboard)
    /// Uses the view model with the specified name.
    case name(String)
}

/// Specifies how to create a view model instance and which view model to use.
@_spi(RiveExperimental)
public enum ViewModelInstanceSource {
    /// Creates a blank instance with no initial values from the specified view model source.
    case blank(from: ViewModelSource)
    /// Creates an instance with default values from the specified view model source.
    case viewModelDefault(from: ViewModelSource)
    /// Creates a named instance from the specified view model source.
    case name(String, from: ViewModelSource)
}

/// A class that represents an instance of a view model, providing access to its properties and data.
///
/// View model instances provide a type-safe interface for accessing and modifying the data structure
/// defined in a Rive file's view model. Properties can be read, written, and observed through streams.
/// View model instances can be bound to state machines to enable data-driven animations.
@_spi(RiveExperimental)
public class ViewModelInstance: Equatable {
    /// The underlying type for the view model instance handle identifier.
    ///
    /// Handle to a view model instance in the C++ runtime. Obtained from the command queue
    /// when an instance is created via `ViewModelInstanceService`, and used in all subsequent
    /// command queue operations. Automatically cleaned up when this `ViewModelInstance`
    /// instance is deallocated via `ViewModelInstanceService.deleteViewModelInstance`.
    typealias ViewModelInstanceHandle = UInt64

    private let dependencies: Dependencies
    let viewModelInstanceHandle: ViewModelInstanceHandle

    @MainActor
    init(for artboard: Artboard, from file: File, dependencies: Dependencies) {
        self.dependencies = dependencies
        self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createBlankViewModelInstance(
            for: artboard,
            from: file
        )
    }

    @MainActor
    init(source: ViewModelInstanceSource, from file: File, dependencies: Dependencies) {
        self.dependencies = dependencies
        switch source {
        case .blank(let viewModelSource):
            switch viewModelSource {
            case .artboardDefault(let artboard):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createBlankViewModelInstance(
                    for: artboard,
                    from: file
                )
            case .name(let viewModelName):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createBlankViewModelInstance(
                    named: viewModelName,
                    from: file
                )
            }
        case .viewModelDefault(let viewModelSource):
            switch viewModelSource {
            case .artboardDefault(let artboard):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createDefaultViewModelInstance(
                    for: artboard,
                    from: file
                )
            case .name(let viewModelName):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createDefaultViewModelInstance(
                    named: viewModelName,
                    from: file
                )
            }
        case .name(let instanceName, let viewModelSource):
            switch viewModelSource {
            case .artboardDefault(let artboard):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createViewModelInstanceNamed(instanceName, for: artboard, from: file)
            case .name(let viewModelName):
                self.viewModelInstanceHandle = dependencies.viewModelInstanceService.createViewModelInstanceNamed(instanceName, viewModelName: viewModelName, from: file)
            }
        }
    }

    @MainActor
    init(handle: ViewModelInstanceHandle, dependencies: Dependencies) {
        self.viewModelInstanceHandle = handle
        self.dependencies = dependencies
    }

    deinit {
        let service = dependencies.viewModelInstanceService
        let handle = viewModelInstanceHandle
        Task { @MainActor in
            guard let deletedHandle = try? await service.deleteViewModelInstance(handle) else { return }
            service.deleteViewModelInstanceListener(deletedHandle)
        }
    }

    /// Compares two ViewModelInstance instances for equality.
    ///
    /// Two view model instance instances are considered equal if they reference the same underlying
    /// view model instance handle. This means they represent the same view model instance in the C++ runtime.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side view model instance instance.
    ///   - rhs: The right-hand side view model instance  instance.
    /// - Returns: `true` if both view model instances reference the same underlying view model instance handle.
    public static func ==(lhs: ViewModelInstance, rhs: ViewModelInstance) -> Bool {
        return lhs.viewModelInstanceHandle == rhs.viewModelInstanceHandle
    }

    // MARK: - StringProperty
    
    /// Retrieves the current value of a string property.
    ///
    /// - Parameter property: The string property to read
    /// - Returns: The current string value of the property
    /// - Throws: An error if the property cannot be read
    @MainActor
    public func value(of property: StringProperty) async throws -> StringProperty.Value {
        return try await dependencies.viewModelInstanceService.stringValue(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits values of a string property as they change.
    ///
    /// The stream emits new values whenever the property changes and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The string property to observe
    /// - Returns: An async throwing stream that emits string values
    @MainActor
    public func valueStream(of property: StringProperty) -> AsyncThrowingStream<StringProperty.Value, Error> {
        return dependencies.viewModelInstanceService.stringValueStream(for: viewModelInstanceHandle, path: property.path)
    }

    /// Sets the value of a string property.
    ///
    /// - Parameters:
    ///   - property: The string property to modify
    ///   - value: The new string value to assign
    @MainActor
    public func setValue(of property: StringProperty, to value: StringProperty.Value) {
        dependencies.viewModelInstanceService.setStringValue(value, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - NumberProperty
    
    /// Retrieves the current value of a number property.
    ///
    /// - Parameter property: The number property to read
    /// - Returns: The current float value of the property
    /// - Throws: An error if the property cannot be read
    @MainActor
    public func value(of property: NumberProperty) async throws -> NumberProperty.Value {
        return try await dependencies.viewModelInstanceService.numberValue(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits values of a number property as they change.
    ///
    /// The stream emits new values whenever the property changes and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The number property to observe
    /// - Returns: An async throwing stream that emits float values
    @MainActor
    public func valueStream(of property: NumberProperty) -> AsyncThrowingStream<NumberProperty.Value, Error> {
        return dependencies.viewModelInstanceService.numberValueStream(for: viewModelInstanceHandle, path: property.path)
    }

    /// Sets the value of a number property.
    ///
    /// - Parameters:
    ///   - property: The number property to modify
    ///   - value: The new float value to assign
    @MainActor
    public func setValue(of property: NumberProperty, to value: NumberProperty.Value) {
        dependencies.viewModelInstanceService.setNumberValue(value, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - BoolProperty
    
    /// Retrieves the current value of a boolean property.
    ///
    /// - Parameter property: The boolean property to read
    /// - Returns: The current boolean value of the property
    /// - Throws: An error if the property cannot be read
    @MainActor
    public func value(of property: BoolProperty) async throws -> BoolProperty.Value {
        return try await dependencies.viewModelInstanceService.boolValue(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits values of a boolean property as they change.
    ///
    /// The stream emits new values whenever the property changes and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The boolean property to observe
    /// - Returns: An async throwing stream that emits boolean values
    @MainActor
    public func valueStream(of property: BoolProperty) -> AsyncThrowingStream<BoolProperty.Value, Error> {
        return dependencies.viewModelInstanceService.boolValueStream(for: viewModelInstanceHandle, path: property.path)
    }

    /// Sets the value of a boolean property.
    ///
    /// - Parameters:
    ///   - property: The boolean property to modify
    ///   - value: The new boolean value to assign
    @MainActor
    public func setValue(of property: BoolProperty, to value: BoolProperty.Value) {
        dependencies.viewModelInstanceService.setBoolValue(value, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - ColorProperty
    
    /// Retrieves the current value of a color property.
    ///
    /// - Parameter property: The color property to read
    /// - Returns: The current color value of the property
    /// - Throws: An error if the property cannot be read
    @MainActor
    public func value(of property: ColorProperty) async throws -> ColorProperty.Value {
        return try await dependencies.viewModelInstanceService.colorValue(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits values of a color property as they change.
    ///
    /// The stream emits new values whenever the property changes and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The color property to observe
    /// - Returns: An async throwing stream that emits color values
    @MainActor
    public func valueStream(of property: ColorProperty) -> AsyncThrowingStream<ColorProperty.Value, Error> {
        return dependencies.viewModelInstanceService.colorValueStream(for: viewModelInstanceHandle, path: property.path)
    }

    /// Sets the value of a color property.
    ///
    /// - Parameters:
    ///   - property: The color property to modify
    ///   - value: The new color value to assign
    @MainActor
    public func setValue(of property: ColorProperty, to value: ColorProperty.Value) {
        dependencies.viewModelInstanceService.setColorValue(value, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - EnumProperty
    
    /// Retrieves the current value of an enum property.
    ///
    /// - Parameter property: The enum property to read
    /// - Returns: The current string value (enum case name) of the property
    /// - Throws: An error if the property cannot be read
    @MainActor
    public func value(of property: EnumProperty) async throws -> EnumProperty.Value {
        return try await dependencies.viewModelInstanceService.enumValue(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits values of an enum property as they change.
    ///
    /// The stream emits new values whenever the property changes and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The enum property to observe
    /// - Returns: An async throwing stream that emits string values (enum case names)
    @MainActor
    public func valueStream(of property: EnumProperty) -> AsyncThrowingStream<EnumProperty.Value, Error> {
        return dependencies.viewModelInstanceService.enumValueStream(for: viewModelInstanceHandle, path: property.path)
    }

    /// Sets the value of an enum property.
    ///
    /// - Parameters:
    ///   - property: The enum property to modify
    ///   - value: The new string value (enum case name) to assign
    @MainActor
    public func setValue(of property: EnumProperty, to value: EnumProperty.Value) {
        dependencies.viewModelInstanceService.setEnumValue(value, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - TriggerProperty

    /// Fires a trigger property, causing any associated state machine transitions or actions to execute.
    ///
    /// Triggers are one-time events that can be used to initiate state transitions or trigger
    /// animations in bound state machines.
    ///
    /// - Parameter trigger: The trigger property to fire
    @MainActor
    public func fire(trigger property: TriggerProperty) {
        dependencies.viewModelInstanceService.fireTrigger(for: viewModelInstanceHandle, path: property.path)
    }

    /// Creates a stream that emits events when a trigger property is fired.
    ///
    /// The stream emits a `Void` value whenever the trigger is fired and continues until it is cancelled
    /// or the view model instance is deallocated.
    ///
    /// - Parameter property: The trigger property to observe
    /// - Returns: An async throwing stream that emits `Void` values when the trigger fires
    @MainActor
    public func stream(of property: TriggerProperty) -> AsyncThrowingStream<Void, Error> {
        return dependencies.viewModelInstanceService.triggerStream(for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - ImageProperty

    /// Sets the value of an image property.
    ///
    /// - Parameters:
    ///   - property: The image property to modify
    ///   - image: The image to assign to the property
    @MainActor
    public func setValue(of property: ImageProperty, to image: Image) {
        dependencies.viewModelInstanceService.setImageValue(image.handle, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - ArtboardProperty

    /// Sets the value of an artboard property.
    ///
    /// - Parameters:
    ///   - property: The artboard property to modify
    ///   - artboard: The artboard to assign to the property
    @MainActor
    public func setValue(of property: ArtboardProperty, to artboard: Artboard) {
        dependencies.viewModelInstanceService.setArtboardValue(artboard, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: ViewModelInstanceProperty

    /// Retrieves the nested view model instance at the specified property path.
    ///
    /// - Parameter property: The view model instance property to read
    /// - Returns: A new `ViewModelInstance` representing the nested instance
    @MainActor
    public func value(of property: ViewModelInstanceProperty) -> ViewModelInstance {
        let service = ViewModelInstanceService(dependencies: dependencies.viewModelInstanceService.dependencies)
        let handle = dependencies.viewModelInstanceService.viewModelInstanceValue(
            for: viewModelInstanceHandle,
            path: property.path,
            observer: service
        )
        return ViewModelInstance(
            handle: handle,
            dependencies: .init(
                viewModelInstanceService: service
            )
        )
    }

    /// Sets the value of a view model instance property.
    ///
    /// - Parameters:
    ///   - property: The view model instance property to modify
    ///   - instance: The view model instance to assign to the property
    @MainActor
    public func setValue(of property: ViewModelInstanceProperty, to instance: ViewModelInstance) {
        dependencies.viewModelInstanceService.setViewModelInstanceValue(instance.viewModelInstanceHandle, for: viewModelInstanceHandle, path: property.path)
    }

    // MARK: - ListProperty

    /// Retrieves the number of items in a list property.
    ///
    /// - Parameter property: The list property to query
    /// - Returns: The number of items in the list
    /// - Throws: An error if the list size cannot be retrieved
    @MainActor
    public func size(of property: ListProperty) async throws -> Int {
        return try await dependencies.viewModelInstanceService.listSize(for: viewModelInstanceHandle, path: property.path)
    }

    /// Appends a view model instance to the end of a list property.
    ///
    /// - Parameters:
    ///   - instance: The view model instance to append
    ///   - list: The list property to modify
    @MainActor
    public func appendInstance(_ instance: ViewModelInstance, to list: ListProperty) {
        dependencies.viewModelInstanceService.appendViewModelInstance(
            viewModelInstanceHandle,
            path: list.path,
            value: instance.viewModelInstanceHandle
        )
    }

    /// Inserts a view model instance into a list property at the specified index.
    ///
    /// - Parameters:
    ///   - instance: The view model instance to insert
    ///   - list: The list property to modify
    ///   - index: The index at which to insert the instance
    @MainActor
    public func insertInstance(_ instance: ViewModelInstance, to list: ListProperty, at index: Int32) {
        dependencies.viewModelInstanceService.insertViewModelInstance(
            viewModelInstanceHandle,
            path: list.path,
            value: instance.viewModelInstanceHandle,
            index: index
        )
    }

    /// Removes a view model instance from a list property at the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of the instance to remove
    ///   - list: The list property to modify
    @MainActor
    public func removeInstance(at index: Int32, from list: ListProperty) {
        dependencies.viewModelInstanceService.removeViewModelInstanceListViewModelAtIndex(
            viewModelInstanceHandle,
            path: list.path,
            index: index,
            value: 0
        )
    }

    /// Removes a specific view model instance from a list property.
    ///
    /// - Parameters:
    ///   - instance: The view model instance to remove
    ///   - list: The list property to modify
    @MainActor
    public func removeInstance(_ instance: ViewModelInstance, from list: ListProperty) {
        dependencies.viewModelInstanceService.removeViewModelInstanceListViewModelByValue(
            viewModelInstanceHandle,
            path: list.path,
            value: instance.viewModelInstanceHandle
        )
    }

    /// Swaps two view model instances in a list property at the specified indices.
    ///
    /// - Parameters:
    ///   - atIndex: The index of the first instance to swap
    ///   - withIndex: The index of the second instance to swap
    ///   - list: The list property to modify
    @MainActor
    public func swapInstance(atIndex: Int32, withIndex: Int32, in list: ListProperty) {
        dependencies.viewModelInstanceService.swapViewModelInstanceListValues(
            viewModelInstanceHandle,
            path: list.path,
            atIndex: atIndex,
            withIndex: withIndex
        )
    }

    /// Retrieves the view model instance at the specified index in a list property.
    ///
    /// - Parameters:
    ///   - property: The list property to read from
    ///   - index: The index of the instance to retrieve
    /// - Returns: A new `ViewModelInstance` representing the instance at the specified index
    @MainActor
    public func value(of property: ListProperty, at index: Int32) -> ViewModelInstance {
        let service = ViewModelInstanceService(dependencies: dependencies.viewModelInstanceService.dependencies)
        let handle = dependencies.viewModelInstanceService.listViewModelInstanceValue(
            for: viewModelInstanceHandle,
            path: property.path,
            index: index,
            observer: service
        )
        return ViewModelInstance(
            handle: handle,
            dependencies: .init(
                viewModelInstanceService: service
            )
        )
    }
}

extension ViewModelInstance {
    /// Container for all dependencies required by a ViewModelInstance instance.
    struct Dependencies {
        /// Provides view model instance-level services via command queue interactions.
        /// Implements `ViewModelInstanceListener` to receive callbacks from the command server.
        let viewModelInstanceService: ViewModelInstanceService
    }
}

/// A protocol that marks types that can be used as property values in view models.
@_spi(RiveExperimental)
public protocol PropertyValue { }

/// A protocol that represents a property in a view model instance.
///
/// Properties are identified by their path, which is a forward-slash-separated string that uniquely
/// identifies the property within the view model hierarchy.
@_spi(RiveExperimental)
public protocol Property {
    /// The path that uniquely identifies this property within the view model.
    var path: String { get }
}

/// A protocol that represents a property that has a readable and writable value.
///
/// Value properties support both reading and writing values, as well as observing value changes
/// through streams.
@_spi(RiveExperimental)
public protocol ValueProperty: Property {
    /// The type of value that this property holds.
    associatedtype Value: PropertyValue
}

/// A property that holds a string value.
@_spi(RiveExperimental)
public struct StringProperty: ValueProperty {
    public typealias Value = String
    public let path: String
    /// Creates a string property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds a numeric (float) value.
@_spi(RiveExperimental)
public struct NumberProperty: ValueProperty {
    public typealias Value = Float
    public let path: String
    /// Creates a number property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds a boolean value.
@_spi(RiveExperimental)
public struct BoolProperty: ValueProperty {
    public typealias Value = Bool
    public let path: String
    /// Creates a boolean property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds a color value.
@_spi(RiveExperimental)
public struct ColorProperty: ValueProperty {
    public typealias Value = Color
    public let path: String
    /// Creates a color property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds an enum value (represented as a string).
@_spi(RiveExperimental)
public struct EnumProperty: ValueProperty {
    public typealias Value = String
    public let path: String
    /// Creates an enum property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that represents a trigger that can be fired to initiate state transitions.
@_spi(RiveExperimental)
public struct TriggerProperty: Property {
    public let path: String
    /// Creates a trigger property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds an image value.
@_spi(RiveExperimental)
public struct ImageProperty: Property {
    public let path: String
    /// Creates an image property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds an artboard value.
@_spi(RiveExperimental)
public struct ArtboardProperty: Property {
    public let path: String
    /// Creates an artboard property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds a nested view model instance.
@_spi(RiveExperimental)
public struct ViewModelInstanceProperty: Property {
    public let path: String
    /// Creates a view model instance property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

/// A property that holds a list of view model instances.
@_spi(RiveExperimental)
public struct ListProperty: Property {
    public let path: String
    /// Creates a list property with the specified path.
    ///
    /// - Parameter path: The path that identifies this property in the view model
    public init(path: String) {
        self.path = path
    }
}

@_spi(RiveExperimental)
extension String: PropertyValue { }
@_spi(RiveExperimental)
extension Float: PropertyValue { }
@_spi(RiveExperimental)
extension Bool: PropertyValue { }
@_spi(RiveExperimental)
extension Color: PropertyValue { }
