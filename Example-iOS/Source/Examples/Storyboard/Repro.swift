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

  var riveViewModel = RiveViewModel(fileName: "favorite_animation", stateMachineName: "FavoriteButtonAnimStateMachine")

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

      Group {

        Button(action: {

          self.setIsFavorite()

        }, label: {

          modelView
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)

        })
        .padding(.bottom, 24)
        .padding(.top, 24)

        HStack(spacing: 16) {

          Button(action: { self.setIsFavorite() }, label: { Text("setIsFavorite") })

          Button(action: { self.setIsNotFavorite() }, label: { Text("setIsNotFavorite") })

        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)

        Button(action: { self.setDefaultState(isTrue: true) }, label: { Text("setDefaultState true") })
          .padding(.bottom, 24)
      }
      .background(Color.black)

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
    if isTrue {
      self.riveViewModel.triggerInput("isActive")
    }
  }

  private func setIsFavorite() {
    self.riveViewModel.triggerInput("isFavorite")
  }

  private func setIsNotFavorite() {
    self.riveViewModel.triggerInput("isNotFavorite")
  }
}

