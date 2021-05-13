import SwiftUI
import Combine
import RiveRuntime

/// Controller manages the state of the Rive animation
class RiveController: ObservableObject {
    let rive: RiveFile
    
    private let resource: String
    @Published var artboard: RiveArtboard?
    @Published var fit: Fit
    @Published var alignment: RiveRuntime.Alignment
    @Published var playback: Playback = Playback.play
    @Published var activeArtboard: String?
    @Published var playAnimation: String?
    @Published var stateMachineInputs: [StateMachineInput] = []
    
    init(
        _ resource: String,
        fit: Fit = Fit.Contain,
        alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center,
        autoplay: Bool = false,
        playAnimation: String? = nil
    ) {
        self.fit = fit
        self.alignment = alignment
        self.playback = autoplay ? Playback.play : Playback.stop
        self.resource = resource
        self.rive = getRiveFile(resourceName: resource)
        self.playAnimation = playAnimation
    }
    
    /// Play animations
    func play() {
        self.playback = Playback.play
    }
    
    /// Pause all animations and state machines
    func pause() {
        self.playAnimation = nil
        self.playback = Playback.pause
    }
    
    /// - Returns a list of animation names
    func artboardNames() -> [String] {
        return rive.artboardNames() as! [String]
    }
    
    /// - Returns a list of animation names
    func animationNames() -> [String] {
        if let names = artboard?.animationNames() {
            return names as! [String]
        } else {
            return []
        }
    }
    
    /// - Returns a list of inputs for the currently active state machine(s)
    func stateMachineNames() -> [String] {
        if let names = artboard?.stateMachineNames() {
            return names as! [String]
        } else {
            return []
        }
    }
}

struct UIRiveView: UIViewRepresentable {
    
    // MARK: - Properties
    
    @ObservedObject var controller: RiveController
    
    // Delegate handlers for loop and play events
    var loopAction: LoopAction = nil
    var playAction: PlaybackAction = nil
    var pauseAction: PlaybackAction = nil
    var inputsAction: InputsAction = nil
    
    // MARK: - UIViewRepresentable
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: controller.rive,
            fit: controller.fit,
            alignment: controller.alignment,
            autoplay: controller.playback == Playback.play,
            artboard: controller.activeArtboard,
            loopDelegate: context.coordinator,
            playDelegate: context.coordinator,
            pauseDelegate: context.coordinator,
            inputsDelegate: context.coordinator
        )
        
        // Update the controller with the correct artboard
        if let artboard = riveView.artboard {
            controller.artboard = artboard
        }
        
        return riveView
    }
 
    /// Called when the view model changes
    func updateUIView(_ uiView: RiveView, context: UIViewRepresentableContext<UIRiveView>) {
        // Set the properties
        uiView.fit = controller.fit
        uiView.alignment = controller.alignment
        
        // Set the artboard only if necessary
        if let artboardName = controller.activeArtboard {
            if !uiView.isArtboard(name: artboardName) {
                // Pause all playback
                uiView.pause()
                // Reconfigure with the new artboard
                uiView.configure(controller.rive, andArtboard: artboardName, andAutoPlay: false)
                controller.artboard = uiView.artboard
            }
        }
        
        // Start playback of an animation if necessary
        if let playAnimation = controller.playAnimation {
            uiView.pause()
            if uiView.animationNames().contains(playAnimation) {
                uiView.play(animationName: playAnimation)
            } else if uiView.stateMachineNames().contains(playAnimation) {
                uiView.play(animationName: playAnimation, isStateMachine: true)
            }
        } else {
            if controller.playback == .play {
                uiView.play()
            } else {
                uiView.pause()
            }
        }
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, loopAction: loopAction, playAction: playAction, pauseAction: pauseAction, inputsAction: inputsAction)
    }
}

extension UIRiveView {
    
    // MARK: - Coordinator
    
    // Coordinator between RiveView and UIRiveView
    class Coordinator: NSObject, LoopDelegate, PlayDelegate, PauseDelegate, InputsDelegate {
        
        private var controller: RiveController
        private var loopAction: LoopAction
        private var playAction: PlaybackAction
        private var pauseAction: PlaybackAction
        private var inputsAction: InputsAction
        var subscribers: [AnyCancellable] = []
        
        init(controller: RiveController, loopAction: LoopAction, playAction: PlaybackAction, pauseAction: PlaybackAction, inputsAction: InputsAction) {
            self.controller = controller
            self.loopAction = loopAction
            self.playAction = playAction
            self.pauseAction = pauseAction
            self.inputsAction = inputsAction
            
            // This stuff is all experimental and may get removed
//            let fitSubscription = controller.$fit.receive(on: RunLoop.main).sink(receiveValue: fitDidChange)
//            subscribers.append(fitSubscription)
        }
        
        // Cancel subscribers when Coordinator is deinitialized
//        deinit {
//            subscribers.forEach { $0.cancel() }
//        }
//
//        var fitDidChange: (Fit) -> Void = { fit in
//            print("Fit changed to \(fit)")
//        }
        
        func loop(_ animationName: String, type: Int) {
                loopAction?(animationName, type)
            }

        func play(_ animationName: String) {
            controller.playback = Playback.play
            playAction?(animationName)
        }
        
        func pause(_ animationName: String) {
            controller.playback = Playback.pause
            pauseAction?(animationName)
        }
        
        func inputs(_ inputs: [StateMachineInput]) {
            print("Got inputs callback")
            controller.stateMachineInputs = inputs
        }
    }
}
