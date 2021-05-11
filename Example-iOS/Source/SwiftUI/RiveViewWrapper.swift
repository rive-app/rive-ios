import SwiftUI
import Combine
import RiveRuntime

/// Controller manages the state of the Rive animation
class RiveController: ObservableObject {
    @Published var fit: Fit
    @Published var alignment: RiveRuntime.Alignment
    @Published var playback = Playback.play
    
    init(
        fit: Fit = Fit.Contain,
        alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center,
        autoplay: Bool = false
    ) {
        self.fit = fit
        self.alignment = alignment
        self.playback = autoplay ? Playback.play : Playback.stop
    }
    
    /// Play animations
    func play() {
        self.playback = Playback.play
    }
    
    /// Pause all animations and state machines
    func pause() {
        self.playback = Playback.pause
    }
}


struct UIRiveView: UIViewRepresentable {
    
    // MARK: - Properties
    
    let resource: String
    @ObservedObject var controller: RiveController
    
    // Delegate handlers for loop and play events
    var loopAction: LoopAction = nil
    var playAction: PlaybackAction = nil
    var pauseAction: PlaybackAction = nil
    
    // MARK: - UIViewRepresentable
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: getRiveFile(resourceName: resource),
            fit: controller.fit,
            alignment: controller.alignment,
            autoplay: controller.playback == Playback.play,
            loopDelegate: context.coordinator,
            playDelegate: context.coordinator,
            pauseDelegate: context.coordinator
        )
        
        // Try out target-action?

        return riveView
    }
 
    /// Called when the view model changes
    func updateUIView(_ uiView: RiveView, context: UIViewRepresentableContext<UIRiveView>) {
        uiView.fit = controller.fit
        uiView.alignment = controller.alignment
        uiView.playback = controller.playback
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        // Coordinator(loopCount: $loopCount)
        Coordinator(controller: controller, loopAction: loopAction, playAction: playAction, pauseAction: pauseAction)
    }
}

extension UIRiveView {
    
    // MARK: - Coordinator
    
    // Coordinator between RiveView and UIRiveView
    class Coordinator: NSObject, LoopDelegate, PlayDelegate, PauseDelegate {
        
        private var controller: RiveController
        private var loopAction: LoopAction
        private var playAction: PlaybackAction
        private var pauseAction: PlaybackAction
        var subscribers: [AnyCancellable] = []
        
        init(controller: RiveController, loopAction: LoopAction, playAction: PlaybackAction, pauseAction: PlaybackAction) {
            self.loopAction = loopAction
            self.playAction = playAction
            self.pauseAction = pauseAction
            self.controller = controller
            
            // This stuff is all experimental and may get removed
            let fitSubscription = controller.$fit.receive(on: RunLoop.main).sink(receiveValue: fitDidChange)
            subscribers.append(fitSubscription)
        }
        
        // Cancel subscribers when Coordinator is deinitialized
        deinit {
            subscribers.forEach { $0.cancel() }
        }
        
        var fitDidChange: (Fit) -> Void = { fit in
            print("Fit changed to \(fit)")
        }
        
        func loop(_ animationName: String, type: Int) {
                loopAction?(animationName, type)
            }

        func play(_ animationName: String) {
            playAction?(animationName)
        }
        
        func pause(_ animationName: String) {
            pauseAction?(animationName)
        }
    }
}
