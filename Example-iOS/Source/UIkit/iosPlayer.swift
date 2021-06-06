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
    weak var viewController:IOSPlayerViewController?
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
    weak var viewController:IOSPlayerViewController?
    
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
        artboardChoices.choices = riveFile!.artboardNames()
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
    
    func _clearOld(){
        
        if (PlayerStack.subviews.count > 3){
            for n in stride(from: PlayerStack.subviews.count-1, through: 3, by: -1){
                PlayerStack.subviews[n].removeFromSuperview()
            }
        }
    }
    
    func _loadAnimations(){
        
        if #available(iOS 14.0, *) {
            
            let artboard = _getArtbaord()
            let animationNames = artboard.animationNames()
            
            if (animationNames.count > 0){
                let label = UILabel()
                label.text = "Animations:"
                label.textColor = .black
                label.heightAnchor.constraint(equalToConstant: 60).isActive = true
                
                PlayerStack.addArrangedSubview(label)
            }
            animationNames.forEach({name in
                
                let label = UILabel()
                label.text = name
                label.textColor = .black
                
                
                let play = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: ">", handler: { [unowned self] _ in
                            self.playerView?.riveView?.play(animationName: name)
                        }))
                let pause = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "||", handler: { [unowned self] _ in
                            self.playerView?.riveView?.pause(animationName: name)
                        }))
                
                let stop = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "[]", handler: { [unowned self] _ in
                            self.playerView?.riveView?.stop(animationName: name)
                        }))
                
                label.heightAnchor.constraint(equalToConstant: 30).isActive = true
                play.heightAnchor.constraint(equalToConstant: 30).isActive = true
                pause.heightAnchor.constraint(equalToConstant: 30).isActive = true
                stop.heightAnchor.constraint(equalToConstant: 30).isActive = true
                play.widthAnchor.constraint(equalToConstant: 40).isActive = true
                pause.widthAnchor.constraint(equalToConstant: 40).isActive = true
                stop.widthAnchor.constraint(equalToConstant: 40).isActive = true

                
                let stackView = UIStackView()
                stackView.translatesAutoresizingMaskIntoConstraints = false
                stackView.axis = .horizontal
                stackView.alignment = .leading
                
                stackView.addArrangedSubview(label)
                stackView.addArrangedSubview(play)
                stackView.addArrangedSubview(pause)
                stackView.addArrangedSubview(stop)
                
                
                PlayerStack.addArrangedSubview(stackView)
            })
        }
    }
    
    func _getArtbaord()->RiveArtboard{
        if let name=artboardName{
            return riveFile!.artboard(fromName:name)
        }
        else {
            return riveFile!.artboard()
        }
    }
    
    func _loadStateMachines(){

        if #available(iOS 14.0, *) {
            let artboard = _getArtbaord()
            let stateMachineNames = artboard.stateMachineNames()
            
            if(stateMachineNames.count > 0){
                let label = UILabel()
                label.text = "StateMachines:"
                label.textColor = .black
                label.heightAnchor.constraint(equalToConstant: 60).isActive = true
                PlayerStack.addArrangedSubview(label)
            }
            
            stateMachineNames.forEach({name in
                
                let label = UILabel()
                label.text = name
                label.textColor = .black
                
                
                let play = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: ">", handler: { [unowned self] _ in
                            self.playerView?.riveView?.play(animationName: name, isStateMachine: true)
                        }))
                let pause = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "||", handler: { [unowned self] _ in
                            self.playerView?.riveView?.pause(animationName: name, isStateMachine: true)
                        }))
                
                let stop = UIButton(
                    type: .system,
                    primaryAction:
                        UIAction(title: "[]", handler: { [unowned self] _ in
                            self.playerView?.riveView?.stop(animationName: name, isStateMachine: true)
                        }))
                
                label.heightAnchor.constraint(equalToConstant: 30).isActive = true
                play.heightAnchor.constraint(equalToConstant: 30).isActive = true
                pause.heightAnchor.constraint(equalToConstant: 30).isActive = true
                stop.heightAnchor.constraint(equalToConstant: 30).isActive = true
                play.widthAnchor.constraint(equalToConstant: 40).isActive = true
                pause.widthAnchor.constraint(equalToConstant: 40).isActive = true
                stop.widthAnchor.constraint(equalToConstant: 40).isActive = true

                
                let stackView = UIStackView()
                stackView.translatesAutoresizingMaskIntoConstraints = false
                stackView.axis = .horizontal
                stackView.alignment = .leading
                
                stackView.addArrangedSubview(label)
                stackView.addArrangedSubview(play)
                stackView.addArrangedSubview(pause)
                stackView.addArrangedSubview(stop)
                
                PlayerStack.addArrangedSubview(stackView)
                // time to add buttons for all the states :P
                
                let stateMachine = artboard.stateMachine(fromName: name)
                stateMachine.inputNames().forEach{inputName in
                    let label = UILabel()
                    label.text = inputName
                    label.textColor = .black
                    
                    let stackView = UIStackView()
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    stackView.axis = .horizontal
                    stackView.alignment = .trailing
                    stackView.addArrangedSubview(label)
                    
                    let input = stateMachine.input(fromName: inputName)
                    if (input.isBoolean()){
                        let switchToggle = UISwitch(
                            frame: CGRect(),
                            primaryAction: UIAction(
                                handler: { [unowned self] this in
                                    if ((this.sender as! UISwitch).isOn){
                                        self.playerView?.riveView.setBooleanState(name, inputName: inputName, value: true)
                                    }
                                    else {
                                        self.playerView?.riveView.setBooleanState(name, inputName: inputName, value: false)
                                    }
                                }
                            )
                        )
                        stackView.addArrangedSubview(switchToggle)
                    }
                    else if (input.isTrigger()){
                        let fireButton = UIButton(
                            type: .system,
                            primaryAction:
                                UIAction(title: "fire", handler: { [unowned self] _ in
                                    self.playerView?.riveView.fireState(name, inputName: inputName)
                                }))
                        stackView.addArrangedSubview(fireButton)
                    }
                    else if (input.isNumber()){
                                
                        let valueLabel = UILabel()
                        valueLabel.text = NSString(format: "%.2f", (input as! RiveStateMachineNumberInput).value()) as String
                        valueLabel.textColor = .black
                        
                        let downButton = UIButton(
                            type: .system,
                            primaryAction:
                                UIAction(title: "-", handler: { [unowned self] _ in
                                    let currentValue = (valueLabel.text! as NSString)
                                    let currentFloat = currentValue.floatValue - 1
                                    valueLabel.text = NSString(format: "%.2f", currentFloat) as String
                                    
                                    self.playerView?.riveView.setNumberState(name, inputName: inputName, value: currentFloat)
                                }))
                        let upButton = UIButton(
                            type: .system,
                            primaryAction:
                                UIAction(title: "+", handler: { [unowned self] _ in
                                    let currentValue = (valueLabel.text! as NSString)
                                    let currentFloat = currentValue.floatValue + 1
                                    valueLabel.text = NSString(format: "%.2f", currentFloat) as String
                                    
                                    self.playerView?.riveView.setNumberState(name, inputName: inputName, value: currentFloat)
                                }))
                        stackView.addArrangedSubview(downButton)
                        stackView.addArrangedSubview(valueLabel)
                        stackView.addArrangedSubview(upButton)
                    }
                    
                    
                    
                    
                    PlayerStack.addArrangedSubview(stackView)
                }
            })
        }
    }
    
    func loadAnimations(){
        _clearOld()
        _loadStateMachines()
        _loadAnimations()
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
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (view as! IOSPlayerView).riveView.stop()
    }
}
