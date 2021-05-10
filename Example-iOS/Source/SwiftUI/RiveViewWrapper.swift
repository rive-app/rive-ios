import SwiftUI
import RiveRuntime

struct UIRiveView: UIViewRepresentable {
    let resource: String
    var fit: Fit = Fit.Contain
    var alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    var playback: Playback = Playback.play
    
    // Delegate handlers for loop and play events
    var loopAction: LoopAction = nil
    var playAction: PlaybackAction = nil
    var pauseAction: PlaybackAction = nil
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: getRiveFile(resourceName: resource),
            fit: fit,
            alignment: alignment,
            autoplay: playback == Playback.play,
            loopDelegate: context.coordinator,
            playDelegate: context.coordinator,
            pauseDelegate: context.coordinator
        )
        return riveView
    }
 
    /// Called when a bound variable changes state
    func updateUIView(_ uiView: RiveView, context: Context) {
        print("updateUI")
        uiView.fit = fit
        uiView.alignment = alignment
        uiView.playback = playback
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        // Coordinator(loopCount: $loopCount)
        Coordinator(loopAction: loopAction, playAction: playAction, pauseAction: pauseAction)
    }
    
}

// Coordinator between RiveView and UIRiveView
class Coordinator: NSObject, LoopDelegate, PlayDelegate, PauseDelegate {

    private var loopAction: LoopAction
    private var playAction: PlaybackAction
    private var pauseAction: PlaybackAction
    
    
    init(loopAction: LoopAction, playAction: PlaybackAction, pauseAction: PlaybackAction) {
        self.loopAction = loopAction
        self.playAction = playAction
        self.pauseAction = pauseAction
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
    
//    @Binding private var loopCount: Int
//
//    init(loopCount: Binding<Int>) {
//        self._loopCount = loopCount
//    }
//
//    func loop(_ animationName: String, type: Int) {
//        loopCount += 1
//    }
}
