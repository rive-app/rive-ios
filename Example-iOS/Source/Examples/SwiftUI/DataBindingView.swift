//
//  DataBindingView.swift
//  Example (iOS)
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

private class DataBindingViewModel: RiveViewModel {
    // A strong reference to an instance must be made in order
    // to properly update an instance's properties. This instance
    // must be the same that was bound to an artboard and/or state machine.
    private(set) var dataBindingInstance: RiveDataBindingViewModel.Instance?

    // Properties get cached as they are created, so returning a property
    // by path from the same instance will return the same object.
    // This way, no strong reference has to be kept. This is the same
    // for all property types.
    var stringProperty: RiveDataBindingViewModel.Instance.StringProperty? {
        return dataBindingInstance?.stringProperty(fromPath: "String")
    }

    var numberProperty: RiveDataBindingViewModel.Instance.NumberProperty? {
        return dataBindingInstance?.numberProperty(fromPath: "Number")
    }

    var booleanProperty: RiveDataBindingViewModel.Instance.BooleanProperty? {
        return dataBindingInstance?.booleanProperty(fromPath: "Boolean")
    }

    var colorProperty: RiveDataBindingViewModel.Instance.ColorProperty? {
        return dataBindingInstance?.colorProperty(fromPath: "Color")
    }

    var enumProperty: RiveDataBindingViewModel.Instance.EnumProperty? {
        return dataBindingInstance?.enumProperty(fromPath: "Enum")
    }

    var viewModelProperty: RiveDataBindingViewModel.Instance? {
        return dataBindingInstance?.viewModelInstanceProperty(fromPath: "Nested")
    }

    init(fileName: String) {
        super.init(fileName: fileName)

        riveModel?.enableAutoBind { [weak self] instance in
            guard let self else { return }
            // Capture the new instance so any new properties
            // can be created from the new instance.
            dataBindingInstance = instance

            stringProperty?.addListener { [weak self] value in
                guard let self, let stringProperty else { return }
                print("Updated value: \(stringProperty.value)")
            }
        }
    }

    func triggerProperty(name: String) -> RiveDataBindingViewModel.Instance.TriggerProperty? {
        return dataBindingInstance?.triggerProperty(fromPath: name)
    }
}

struct DataBindingView: DismissableView {
    var dismiss: () -> Void = {}

    @StateObject private var riveViewModel = DataBindingViewModel(fileName: "data_binding_test")
    @State var isDismissing = false

    var body: some View {
        riveViewModel
            .view()
            .onAppear {
                // Make sure an instance is bound. If so, start looping every 500ms
                // and randomize the values of all instance properties.
                guard let instance = riveViewModel.dataBindingInstance else { return }
                loop(instance)
            }.onDisappear {
                isDismissing = true
            }
    }

    private func loop(_ instance: RiveDataBindingViewModel.Instance) {
        updateString()
        updateNumber()
        updateBoolean()
        updateColor()
        updateEnum()
        updateNestedViewModel()
        updateTrigger()

        // Manually advance the Rive view since it is not playing.
        // When a Rive view is playing, this is handled for you.
        riveViewModel.riveView?.advance(delta: 0)

        if !isDismissing {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                loop(instance)
            }
        }
    }

    private func updateString() {
        guard let property = riveViewModel.stringProperty else { return }
        let team = [
            "Adam",
            "David",
            "Erik",
            "Gordon",
            "Tod"
        ]
        let string = team.randomElement()!
        property.value = string
    }

    private func updateNumber() {
        guard let property = riveViewModel.numberProperty else { return }
        let number = Int.random(in: 1...10)
        property.value = Float(number)
    }

    private func updateBoolean() {
        guard let property = riveViewModel.booleanProperty else { return }
        let value = property.value
        property.value = !value
    }

    private func updateColor() {
        guard let property = riveViewModel.colorProperty else { return }
        let colors: [UIColor] = [
            .black,
            .blue,
            .brown,
            .cyan,
            .gray,
            .green,
            .orange,
            .red,
            .yellow
        ]
        property.value = colors.randomElement()!
    }

    private func updateEnum() {
        guard let property = riveViewModel.enumProperty else { return }
        let random = property.values.randomElement()!
        property.value = random
    }

    private func updateNestedViewModel() {
        guard let nested = riveViewModel.viewModelProperty,
              let property = nested.stringProperty(fromPath: "String")
        else { return }
        let team = [
            "Adam",
            "David",
            "Erik",
            "Gordon",
            "Tod"
        ]
        let string = team.randomElement()!
        property.value = string
    }

    private func updateTrigger() {
        let triggers = [
            "Trigger Red",
            "Trigger Green",
            "Trigger Blue"
        ]
        let trigger = triggers.randomElement()!
        guard let property = riveViewModel.triggerProperty(name: trigger) else { return }
        property.trigger()
    }
}

