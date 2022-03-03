import SwiftUI
import Combine
import RiveRuntime

/// Controller manages the state of the Rive animation
class RiveExplorerController: ObservableObject {
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
        fit: Fit = .fitContain,
        alignment: RiveRuntime.Alignment = .alignmentCenter,
        autoplay: Bool = false,
        playAnimation: String? = nil
    )  {
        self.fit = fit
        self.alignment = alignment
        self.playback = autoplay ? .play : .stop
        self.resource = resource
        // TODO: fix this
        self.rive = (try? getRiveFile(resourceName: resource))!
        self.playAnimation = playAnimation
    }
    
    /// Play animations
    func play() {
        self.playback = .play
    }
    
    /// Pause all animations and state machines
    func pause() {
        self.playAnimation = nil
        self.playback = .pause
    }
    
    /// - Returns a list of animation names
    func artboardNames() -> [String] {
        return rive.artboardNames()
    }
    
    /// - Returns a list of animation names
    func animationNames() -> [String] {
        if let names = artboard?.animationNames() {
            return names
        } else {
            return []
        }
    }
    
    /// - Returns a list of inputs for the currently active state machine(s)
    func stateMachineNames() -> [String] {
        if let names = artboard?.stateMachineNames() {
            return names
        } else {
            return []
        }
    }
}

struct RiveExplorerBridge: UIViewRepresentable {
    
    // MARK: - Properties
    
    @ObservedObject var controller: RiveExplorerController
    
    // Delegate handlers for loop and play events
    var loopAction: LoopAction = nil
    var playAction: PlaybackAction = nil
    var pauseAction: PlaybackAction = nil
    var inputsAction: InputsAction = nil
    
    // MARK: - UIViewRepresentable
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        
        do {
            let riveView = try RiveView(
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
        catch {
            return RiveView()
        }
    }
    
    /// Called when the view model changes
    func updateUIView(_ uiView: RiveView, context: UIViewRepresentableContext<RiveExplorerBridge>) {
        // Set the properties
        uiView.fit = controller.fit
        uiView.alignment = controller.alignment
        
        // Set the artboard only if necessary
        if let artboardName = controller.activeArtboard {
            if !uiView.isArtboard(name: artboardName) {
                // Pause all playback
                uiView.pause()
                // Reconfigure with the new artboard
                try? uiView.configure(controller.rive, andArtboard: artboardName, andAutoPlay: false)
                controller.artboard = uiView.artboard
            }
        }
        
        // Start playback of an animation if necessary
        if let playAnimation = controller.playAnimation {
            uiView.pause()
            if uiView.animationNames().contains(playAnimation) {
                try? uiView.play(animationName: playAnimation)
            } else if uiView.stateMachineNames().contains(playAnimation) {
                try? uiView.play(animationName: playAnimation, isStateMachine: true)
            }
        } else {
            if controller.playback == .play {
                try? uiView.play()
            } else {
                uiView.pause()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: RiveView, coordinator: Self.Coordinator) {
        uiView.stop()
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, loopAction: loopAction, playAction: playAction, pauseAction: pauseAction, inputsAction: inputsAction)
    }
}

extension RiveExplorerBridge {
    
    // MARK: - Coordinator
    
    // Coordinator between RiveView and UIRiveView
    class Coordinator: NSObject, LoopDelegate, PlayDelegate, PauseDelegate, InputsDelegate {
        
        private var controller: RiveExplorerController
        private var loopAction: LoopAction
        private var playAction: PlaybackAction
        private var pauseAction: PlaybackAction
        private var inputsAction: InputsAction
        var subscribers: [AnyCancellable] = []
        
        init(controller: RiveExplorerController, loopAction: LoopAction, playAction: PlaybackAction, pauseAction: PlaybackAction, inputsAction: InputsAction) {
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
        
        func play(_ animationName: String, isStateMachine: Bool) {
            controller.playback = .play
            playAction?(animationName)
        }
        
        func pause(_ animationName: String, isStateMachine: Bool) {
            controller.playback = .pause
            pauseAction?(animationName)
        }
        
        func inputs(_ inputs: [StateMachineInput]) {
            print("Got inputs callback")
            controller.stateMachineInputs = inputs
        }
    }
}
