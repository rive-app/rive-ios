//
//  ExamplesMaster.swift
//  RiveExample
//
//  Created by Zachary Duncan on 4/19/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class ExamplesMasterTableViewController: UITableViewController {
    private let storyboardIDs: [String] = [
        "Simple Animation",
        "Layout",
        "MultipleAnimations",
        "Loop Mode",
        "State Machine",
//        "iOS Player",
        "Blend Mode",
        "Slider Widget"
    ]
    
    private enum SwiftViews: StringLiteralType, CaseIterable {
        case components = "Widget Collection"
        case simpleAnimation = "Simple Animation"
        case layout = "Layout"
        case multiple = "MultipleAnimations"
        case loop = "Loop Mode"
        case stateMachine = "State Machine"
        case mesh = "Mesh Animation"
    }
    
    private let viewModels: [(String, RiveViewModel)] = [
        ("Slider Widget",       RiveSlider())
    ]
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storyboardIDs.count + SwiftViews.allCases.count + viewModels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let cell = UITableViewCell()
        
        // ViewControllers made from Storyboard IDs
        if i < storyboardIDs.count {
            cell.textLabel?.text = storyboardIDs[indexPath.row]
        }
        
        // Views made by custom SwiftUI Views
        else if i < storyboardIDs.count + SwiftViews.allCases.count {
            cell.textLabel?.text = SwiftViews.allCases[i - storyboardIDs.count].rawValue
        }
        
        // Views made by the ViewModels
        else {
            cell.textLabel?.text = viewModels[i - (storyboardIDs.count + SwiftViews.allCases.count)].0
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let i = indexPath.row
        var controller: UIViewController
        
        // ViewControllers made from Storyboard IDs
        if i < storyboardIDs.count {
            controller = storyboard!.instantiateViewController(withIdentifier: storyboardIDs[i])
        }
        
        // Views made by custom SwiftUI Views
        else if i < storyboardIDs.count + SwiftViews.allCases.count {
            var anyView: AnyView
            
            switch SwiftViews.allCases[i - storyboardIDs.count] {
            case .components:       anyView = typeErased(dismissableView: RiveComponents())
            case .simpleAnimation:  anyView = typeErased(dismissableView: SwiftSimpleAnimation())
            case .layout:           anyView = typeErased(dismissableView: SwiftLayout())
            case .multiple:         anyView = typeErased(dismissableView: SwiftMultipleAnimations())
            case .loop:             anyView = typeErased(dismissableView: SwiftLoopMode())
            case .stateMachine:     anyView = typeErased(dismissableView: SwiftStateMachine())
            case .mesh:             anyView = typeErased(dismissableView: SwiftMeshAnimation())
            }
            
            controller = UIHostingController(rootView: anyView)
        }
        
        // Views made by the ViewModels
        else {
            let anyView = AnyView(viewModels[i - (storyboardIDs.count + SwiftViews.allCases.count)].1.view())
            controller = UIHostingController(rootView: anyView)
        }
        
        splitViewController?.showDetailViewController(controller, sender: self)
    }
    
    private func typeErased<Content: DismissableView>(dismissableView: Content) -> AnyView {
        var view = dismissableView
        view.dismiss = {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
        
        return AnyView(view)
    }
}

public protocol DismissableView: View {
    init()
    var dismiss: () -> Void { get set }
}
