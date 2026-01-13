//
//  Blinko.swift
//  RiveExample
//
//  Created by David Skuza on 1/9/26.
//  Copyright © 2026 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

struct BlinkoView: DismissableView {
    var dismiss: () -> Void = {}

    @StateObject var viewModel: RiveViewModel = {
        let viewModel = RiveViewModel(fileName: "blinko")
        viewModel.riveModel?.enableAutoBind { _ in }
        return viewModel
    }()

    var body: some View {
        viewModel.view()
    }
}
