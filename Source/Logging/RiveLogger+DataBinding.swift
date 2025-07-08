//
//  RiveLogger+DataBinding.swift
//  RiveRuntime
//
//  Created by David Skuza on 2/10/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
import OSLog

private protocol DataBindingEvent { }

enum RiveLoggerDataBindingEvent {
    enum ViewModel: DataBindingEvent {
        case createdInstanceFromIndex(Int, Bool)
        case createdInstanceFromName(String, Bool)
        case createdDefaultInstance(Bool)
        case createdInstance(Bool)
    }
    enum Instance: DataBindingEvent {
        case property(String, Bool)
        case stringProperty(String, Bool)
        case numberProperty(String, Bool)
        case booleanProperty(String, Bool)
        case colorProperty(String, Bool)
        case enumProperty(String, Bool)
        case viewModelProperty(String, Bool)
        case triggerProperty(String, Bool)
        case imageProperty(String, Bool)
        case listProperty(String, Bool)
    }
    enum Property: DataBindingEvent {
        case propertyUpdated(String, String)
        case propertyTriggered(String)
    }
}

extension RiveLogger {
    private static let dataBinding = Logger(subsystem: subsystem, category: "rive-data-binding")

    // MARK: - Log

    static func log(viewModelRuntime viewModel: RiveDataBindingViewModel, event: RiveLoggerDataBindingEvent.ViewModel) {
        switch event {
        case .createdInstanceFromIndex(let index, let created):
            _log(event: event, level: .debug) {
                let start = created ? "Created" : "Could not create"
                dataBinding.debug("[\(viewModel.name)] \(start) instance from index \(index)")
            }
        case .createdInstanceFromName(let name, let created):
            _log(event: event, level: .debug) {
                let start = created ? "Created" : "Could not create"
                dataBinding.debug("[\(viewModel.name)] \(start) instance from name \(name)")
            }
        case .createdDefaultInstance(let created):
            _log(event: event, level: .debug) {
                let start = created ? "Created" : "Could not create"
                dataBinding.debug("[\(viewModel.name)] \(start) default instance")
            }
        case .createdInstance(let created):
            _log(event: event, level: .debug) {
                let start = created ? "Created" : "Could not create"
                dataBinding.debug("[\(viewModel.name)] \(start) new instance")
            }
        }
    }

    static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, event: RiveLoggerDataBindingEvent.Instance) {
        switch event {
        case .property(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "base", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .stringProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "string", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .numberProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "number", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .booleanProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "boolean", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .colorProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "color", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .enumProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "enum", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .viewModelProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "view model", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .triggerProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "trigger", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .imageProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "image", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        case .listProperty(let path, let found):
            _log(event: event, level: .debug) {
                let message = message(instance: instance, for: "list", path: path, found: found)
                dataBinding.debug("\(message)")
            }
        }
    }

    static func log(event: RiveLoggerDataBindingEvent.Property) {
        switch event {
        case .propertyUpdated(let name, let value):
            _log(event: event, level: .debug) {
                dataBinding.debug("[\(name)] Updated property value to \(value)")
            }
        case .propertyTriggered(let name):
            _log(event: event, level: .debug) {
                dataBinding.debug("[\(name)] Triggered")
            }
        }
    }

    // MARK: - RiveDataBindingViewModel

    @objc static func log(viewModelRuntime runtime: RiveDataBindingViewModel, createdInstanceFromIndex index: Int, created: Bool) {
        Self.log(viewModelRuntime: runtime, event: .createdInstanceFromIndex(index, created))
    }

    @objc static func log(viewModelRuntime runtime: RiveDataBindingViewModel, createdInstanceFromName name: String, created: Bool) {
        Self.log(viewModelRuntime: runtime, event: .createdInstanceFromName(name, created))
    }

    @objc static func logViewModelRuntimeCreatedDefaultInstance(_ runtime: RiveDataBindingViewModel, created: Bool) {
        Self.log(viewModelRuntime: runtime, event: .createdDefaultInstance(created))
    }

    @objc static func logViewModelRuntimeCreatedInstance(_ runtime: RiveDataBindingViewModel, created: Bool) {
        Self.log(viewModelRuntime: runtime, event: .createdInstance(created))
    }

    // MARK: - RiveDataBindingViewModelInstance

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, propertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .property(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, stringPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .stringProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, numberPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .numberProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, booleanPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .booleanProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, colorPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .colorProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, enumPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .enumProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, viewModelPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .viewModelProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, triggerPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .triggerProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, imagePropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .imageProperty(path, found))
    }

    @objc static func log(viewModelInstance instance: RiveDataBindingViewModel.Instance, listPropertyAtPath path: String, found: Bool) {
        Self.log(viewModelInstance: instance, event: .listProperty(path, found))
    }

    // MARK: - Properties

    @objc(logPropertyUpdated:value:) static func log(propertyUpdated property: RiveDataBindingViewModel.Instance.Property, value: String) {
        Self.log(event: .propertyUpdated(property.name, value))
    }

    @objc(logPropertyTriggered:) static func log(propertyTriggered property: RiveDataBindingViewModel.Instance.Property) {
        Self.log(event: .propertyTriggered(property.name))
    }

    // MARK: - Private

    private static func _log(event: DataBindingEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.dataBinding),
              levels.contains(level)
        else { return }

        log()
    }

    private static func message(instance: RiveDataBindingViewModel.Instance, for type: String, path: String, found: Bool) -> String {
        if found {
            return "[\(instance.name)] Found \(type) property at path \(path)"
        } else {
            return "[\(instance.name)] Could not find \(type) property at path \(path)"
        }
    }
}
