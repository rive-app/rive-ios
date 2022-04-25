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
    // MARK: UIKit Examples (sourced from the Main storyboard)
    private let storyboardIDs: [String] = [
        "Simple Animation",
        "Layout",
        "MultipleAnimations",
        //"Loop Mode",
        "State Machine",
        //"iOS Player",
        "Blend Mode",
        "Slider Widget"
    ]
    
    // MARK: SwiftUI Examples (made from custom Views)
    private lazy var swiftViews: [(String, AnyView)] = [
        ("Widget Collection",   typeErased(dismissableView: RiveComponents())),
        ("Simple Animation",    typeErased(dismissableView: SwiftSimpleAnimation())),
        ("Layout",              typeErased(dismissableView: SwiftLayout())),
        ("MultipleAnimations",  typeErased(dismissableView: SwiftMultipleAnimations())),
        ("Loop Mode",           typeErased(dismissableView: SwiftLoopMode())),
        ("State Machine",       typeErased(dismissableView: SwiftStateMachine())),
        ("Mesh Animation",      typeErased(dismissableView: SwiftMeshAnimation()))
    ]
    
    // MARK: SwiftUI Examples (displays the default .view() for custom RiveViewModels)
    private let viewModels: [(String, RiveViewModel)] = [
        ("Slider Widget",       RiveSlider())
    ]
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storyboardIDs.count + swiftViews.count + viewModels.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
//        var sectionCount: Int
        
//        if (storyboardIDs.count > 0) &&
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let cell = UITableViewCell()
        
        // ViewControllers made from Storyboard IDs
        if i < storyboardIDs.count {
            cell.textLabel?.text = storyboardIDs[indexPath.row]
        }
        
        // Views made by custom SwiftUI Views
        else if i < storyboardIDs.count + swiftViews.count {
            cell.textLabel?.text = swiftViews[i - storyboardIDs.count].0
        }
        
        // Views made by the ViewModels
        else {
            cell.textLabel?.text = viewModels[i - (storyboardIDs.count + swiftViews.count)].0
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
        else if i < storyboardIDs.count + swiftViews.count {
            controller = UIHostingController(rootView: swiftViews[i - storyboardIDs.count].1)
        }
        
        // Views made by the ViewModels
        else {
            let anyView = AnyView(viewModels[i - (storyboardIDs.count + swiftViews.count)].1.view())
            controller = UIHostingController(rootView: anyView)
        }
        
        navigationController?.pushViewController(controller, animated: true)
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
