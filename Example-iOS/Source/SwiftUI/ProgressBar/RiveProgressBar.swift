//
//  RiveProgressBar.swift
//  RiveExample
//
//  Created by Matt Sullivan on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

import SwiftUI

struct RiveProgressBar: View {
    
    let resource: String
    
    @Binding var health: Double
    
    var body: some View {
        VStack {
            RiveProgressBarBridge(health: $health)
                .frame(width: 300, height: 75)
        }
    }
}

struct RiveProgressBar_Previews: PreviewProvider {
    static var previews: some View {
    
        
        RiveProgressBar(resource: "liquid", health: Binding.constant(50.0))
    }
}
