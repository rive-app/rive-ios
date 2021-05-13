//
//  iosPlayer.swift
//  RiveExample
//
//  Created by Maxwell Talbot on 13/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class IOSPlayerView: UIView {
    typealias ButtonAction = ()->Void
    
    @IBOutlet var riveView: RiveView!
}

class FileChoiceDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let choices = ["artboard_animations", "basketball", "clipping", "explorer", "f22", "flux_capacitor", "loopy", "mascot", "neostream", "off_road_car_blog", "progress", "pull", "rope", "skills", "trailblaze", "ui_swipe_left_to_delete", "vader", "wacky", "juice_v7", "truck_v7"]
    var chosen = "skills"
    var viewController:IOSPlayerViewController?
    //MARK: - Pickerview method
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
   }
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
       return choices.count
   }
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
       return choices[row]
   }
   func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.chosen = choices[row]
        viewController?.load(name:choices[row])
   }
}

class ArtboardChoicesDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    var choices = [""]
    var chosen:String?
    var viewController:IOSPlayerViewController?
    
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
   }
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
       return choices.count
   }
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
       return choices[row]
   }
   func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.chosen = choices[row]
        viewController?.loadArtboard(name:choices[row])
   }
}

class IOSPlayerViewController: UIViewController {
    var riveFile:RiveFile?
    var playerView:IOSPlayerView?
    var artboardName:String?
    let fileChoices = FileChoiceDelegate()
    let artboardChoices = ArtboardChoicesDelegate()
    
    @IBOutlet var PlayerStack: UIStackView!
    @IBOutlet var FileChoicePicker: UIPickerView!
    @IBOutlet var ArtboardPicker: UIPickerView!
    
    func load(name:String){
        riveFile = getRiveFile(resourceName: name)
        playerView?.riveView.configure(
            riveFile!
        )
        artboardChoices.choices = riveFile!.artboardNames() as! [String]
        ArtboardPicker.reloadComponent(0)
        loadAnimations()
    }
    
    func loadArtboard(name:String){
        playerView?.riveView.configure(
            riveFile!, andArtboard: name
        )
        artboardName=name
        loadAnimations()
    }
    
    func loadAnimations(){
        
        if (PlayerStack.subviews.count > 3){
            for n in stride(from: PlayerStack.subviews.count-1, through: 3, by: -1){
                PlayerStack.subviews[n].removeFromSuperview()
            }
        }
        
        
        var animationNames = [String]()
        if (artboardName == nil){
            animationNames = riveFile?.artboard().animationNames() as! [String]
        }
        else {
            animationNames = riveFile?.artboard(fromName: artboardName!).animationNames() as! [String]
        }
        
        if #available(iOS 14.0, *) {
            animationNames.forEach({name in
                
                let label = UILabel()
                label.text = name
                label.textColor = .black
                
                
                let play = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: ">", handler: { _ in
                            self.playerView?.riveView?.play(animationName: name)
                        }))
                let pause = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "||", handler: { _ in
                            self.playerView?.riveView?.pause(animationName: name)
                        }))
                let stop = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "[]", handler: { _ in
                            self.playerView?.riveView?.stop(animationName: name)
                        }))
                
                
                let stackView = UIStackView()
                stackView.translatesAutoresizingMaskIntoConstraints = false
                stackView.axis = .horizontal
                stackView.spacing = 16
                stackView.distribution = .fill
                stackView.addArrangedSubview(label)
                stackView.addArrangedSubview(play)
                stackView.addArrangedSubview(pause)
                stackView.addArrangedSubview(stop)
                
    //            stackView.alignment = .fill
                
                PlayerStack.addArrangedSubview(stackView)
            })
        }
        PlayerStack.reloadInputViews()
    }
    
    override public func loadView() {
        super.loadView()
        FileChoicePicker.dataSource = fileChoices
        FileChoicePicker.delegate = fileChoices
        fileChoices.viewController = self
        
        ArtboardPicker.dataSource = artboardChoices
        ArtboardPicker.delegate = artboardChoices
        artboardChoices.viewController = self
        
        playerView = view as? IOSPlayerView
        load(name:fileChoices.chosen)
        
    }
}
