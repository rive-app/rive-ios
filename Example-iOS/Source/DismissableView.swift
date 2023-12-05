//
//  DismissableView.swift
//  RiveExample
//
//  Created by Peter G Hayes on 03/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import SwiftUI

public protocol DismissableView: View {
    init()
    var dismiss: () -> Void { get set }
}
