//
//  ContentView.swift
//  Example (tvOS)
//
//  Created by David Skuza on 10/29/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import SwiftUI
import UIKit
import RiveRuntime

class ContentViewModel: ObservableObject {
    struct State: Equatable {
        let first: Bool
        let big: Bool

        init(first: Bool = true, big: Bool = true) {
            self.first = first
            self.big = big
        }
    }

    private let rive: RiveViewModel
    private var state = State() {
        didSet {
            rive.setInput("Big", value: state.big)
            rive.setInput("First", value: state.first)
        }
    }

    init(rive: RiveViewModel) {
        self.rive = rive
    }

    func start() {
        let upGesture = UITapGestureRecognizer(target: self, action: #selector(up))
        let up = UIPress.PressType.upArrow
        upGesture.allowedPressTypes = [NSNumber(integerLiteral: up.rawValue)]
        rive.riveView?.addGestureRecognizer(upGesture)

        let downGesture = UITapGestureRecognizer(target: self, action: #selector(down))
        let down = UIPress.PressType.downArrow
        downGesture.allowedPressTypes = [NSNumber(integerLiteral: down.rawValue)]
        rive.riveView?.addGestureRecognizer(downGesture)

        let leftGesture = UITapGestureRecognizer(target: self, action: #selector(left))
        let left = UIPress.PressType.leftArrow
        leftGesture.allowedPressTypes = [NSNumber(integerLiteral: left.rawValue)]
        rive.riveView?.addGestureRecognizer(leftGesture)

        let rightGesture = UITapGestureRecognizer(target: self, action: #selector(right))
        let right = UIPress.PressType.rightArrow
        rightGesture.allowedPressTypes = [NSNumber(integerLiteral: right.rawValue)]
        rive.riveView?.addGestureRecognizer(rightGesture)
    }

    @objc func up() {
        let newState = State(first: state.first, big: true)
        guard newState != state else { return }
        state = newState
    }

    @objc func down() {
        let newState = State(first: state.first, big: false)
        guard newState != state else { return }
        state = newState
    }

    @objc func left() {
        let newState = State(first: true, big: state.big)
        guard newState != state else { return }
        state = newState

    }

    @objc func right() {
        let newState = State(first: false, big: state.big)
        guard newState != state else { return }
        state = newState
    }
}

struct ContentView: View {
    @StateObject var rive: RiveViewModel
    @StateObject var viewModel: ContentViewModel

    init() {
        let rive = RiveViewModel(fileName: "streaming")
        _rive = StateObject(wrappedValue: rive)

        let viewModel = ContentViewModel(rive: rive)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        rive
            .view()
            .onAppear {
                viewModel.start()
            }
    }
}

#Preview {
    ContentView()
}
