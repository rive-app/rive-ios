//
//  Repro.swift
//  RiveExample
//
//  Created by Daiki Takano on 2024/09/12.
//  Copyright © 2024 Rive. All rights reserved.
//

import UIKit
import RiveRuntime
import SwiftUI

class ReproViewController: UIViewController {

  var riveViewModel = RiveViewModel(fileName: "runtime_nested_inputs", stateMachineName: "MainStateMachine")

  init() {

    super.init(nibName: nil, bundle: nil)

    setDefaultState(isTrue: true)

  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let model = self.riveViewModel
    let modelView = model.view()

    let hostingController = UIHostingController(rootView: {

      Button(action: {

      }, label: {

        modelView
          .aspectRatio(contentMode: .fit)
          .frame(width: 50, height: 50)

      })

    }())

    addChild(hostingController)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hostingController.view)

    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    hostingController.didMove(toParent: self)
  }

  private func setDefaultState(isTrue: Bool) {

    self.riveViewModel.setInput("CircleOuterState", value: isTrue, path: "CircleOuter")

  }
}

