//
//  RViewModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation

open class RViewModel {
    var model: RModel
    
    public init(_ model: RModel) {
        self.model = model
    }
    
    public convenience init(asset: String) {
        self.init(RModel(asset: asset))
    }
    
    // MARK: -
    
    public static var riveslider: RViewModel {
        let model = RModel(asset: "riveslider7", stateMachine: "Slide")
        return RViewModel(model)
    }
}
