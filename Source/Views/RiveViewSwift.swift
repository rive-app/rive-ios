//
//  RiveViewSwift.swift
//  RiveRuntime
//
//  Created by Zach Plata on 2/27/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation
import SwiftUI


// ok we need to structure this a different way. as we're going to leak memory
public class RiveController {
    public init(){}
    
    var riveView:RiveView? = nil
    
    public func registerView(
        _ view: RiveView
    ) {
        riveView = view
    }
    
    public func deregisterView(){
        riveView = nil
    }
    
    public func reset() throws {
        try riveView?.reset()
    }
    
    public func play(
        _ loop: Loop = .loopAuto,
        _ direction: Direction = .directionAuto
    ) throws {
        try riveView?.play(loop:loop, direction: direction)
    }
    
    public func play(
        _ animationName: String,
        _ loop: Loop = .loopAuto,
        _ direction: Direction = .directionAuto,
        _ isStateMachine: Bool = false
    ) throws {
        try riveView?.play(
            animationName: animationName,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    public func play(
        _ animationNames: [String],
        _ loop: Loop = .loopAuto,
        _ direction: Direction = .directionAuto,
        _ isStateMachine: Bool = false
    ) throws {
        try riveView?.play(
            animationNames: animationNames,
            loop: loop,
            direction: direction,
            isStateMachine: isStateMachine
        )
    }
    
    public func pause() {
        riveView?.pause()
    }
    
    public func pause(
        _ animationName: String,
        _ isStateMachine: Bool = false
    ) {
        riveView?.pause(
            animationName: animationName,
            isStateMachine: isStateMachine
        )
    }
    
    public func pause(
        _ animationNames: [String],
        _ isStateMachine: Bool = false
    ) {
        riveView?.pause(
            animationNames: animationNames,
            isStateMachine: isStateMachine
        )
    }
    
    
    public func stop() {
        riveView?.stop()
    }
    
    public func stop(
        _ animationNames: [String],
        _ isStateMachine: Bool = false
    ) {
        riveView?.stop(
            animationNames: animationNames,
            isStateMachine: isStateMachine
        )
    }
    
    
    public func stop(
        _ animationName: String,
        _ isStateMachine: Bool = false
    ) {
        riveView?.stop(
            animationName: animationName,
            isStateMachine: isStateMachine
        )
    }
    
    public func fireState(_ stateMachineName: String, inputName: String) throws {
        try riveView?.fireState(stateMachineName, inputName: inputName)
    }
    
    open func setBooleanState(_ stateMachineName: String, inputName: String, value: Bool) throws {
        try riveView?.setBooleanState(stateMachineName, inputName: inputName, value: value)
    }

    open func setNumberState(_ stateMachineName: String, inputName: String, value: Float) throws {
        try riveView?.setNumberState(stateMachineName, inputName: inputName, value: value)
    }
    
}

enum RiveViewError: Error {
    case noResourceOrHttpUrl
}

@available(iOS 13.0, *)
public struct RiveViewSwift: UIViewRepresentable {
    let resource: String?
    let httpUrl: String?
    let autoplay: Bool
    let artboard: String?
    let animation: String?
    let stateMachine: String?
    let controller: RiveController?
    @Binding var fit: Fit
    @Binding var alignment: RiveRuntime.Alignment
    
    public init(
        resource: String,
        fit: Binding<Fit> = .constant(.fitContain),
        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
        autoplay: Bool = true,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        controller: RiveController? = nil
    ) {
        self.resource = resource
        self.httpUrl = nil
        
        self.autoplay = autoplay
        self.artboard = artboard
        self.animation = animation
        self.stateMachine = stateMachine
        
        self._fit = fit
        self._alignment = alignment
        
        self.controller = controller
    }
    
    public init(
        httpUrl: String,
        fit: Binding<Fit> = .constant(.fitContain),
        alignment: Binding<RiveRuntime.Alignment> = .constant(.alignmentCenter),
        autoplay: Bool = true,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        controller: RiveController? = nil
    ) {
        self.resource = nil
        self.httpUrl = httpUrl
        
        self.autoplay = autoplay
        self.artboard = artboard
        self.animation = animation
        self.stateMachine = stateMachine
        
        self._fit = fit
        self._alignment = alignment
        
        self.controller = controller
    }
    
    /// Constructs the view
    public func makeUIView(context: Context) -> RiveView {
        var riveView: RiveView
        if let resource = resource {
            riveView = try! RiveView(
                resource: resource,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboard: artboard,
                animation: animation,
                stateMachine: stateMachine
            )
        }
        else if let httpUrl = httpUrl {
            riveView = try! RiveView(
                httpUrl: httpUrl,
                fit: fit,
                alignment: alignment,
                autoplay: autoplay,
                artboard: artboard,
                animation: animation,
                stateMachine: stateMachine
            )
        }
        else {
            riveView = RiveView()
        }
        
        controller?.registerView(riveView)
        return riveView
    }
    
    public func updateUIView(
        _ riveView: RiveView,
        context: UIViewRepresentableContext<RiveViewSwift>
    ) {
        if (fit != riveView.fit){
            riveView.fit = fit
        }
        if (alignment != riveView.alignment) {
            riveView.alignment = alignment
        }
        
    }
    
    public static func dismantleUIView(
        _ riveView: RiveView,
        coordinator: Self.Coordinator
    ) {
        riveView.stop()
        
        // TODO: this doesn't work, does the view need a controller ref?
        // controller?.deregisterView()
    }
    
}
