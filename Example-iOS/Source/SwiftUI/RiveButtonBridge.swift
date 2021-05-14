import SwiftUI
import RiveRuntime

struct RiveButtonBridge: UIViewRepresentable {
    let resource: String
    var fit: Fit = .contain
    var alignment: RiveRuntime.Alignment = .center
    var artboard: String? = nil
    var animation: String? = nil
    
    /// Controls whether Rive is playing or paused
    @Binding var play: Bool
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: getRiveFile(resourceName: resource),
            fit: fit,
            alignment: alignment,
            artboard: artboard,
            animation: animation,
            playDelegate: context.coordinator,
            pauseDelegate: context.coordinator,
            stopDelegate: context.coordinator
        )
        return riveView
    }

    func updateUIView(_ riveView: RiveView, context: UIViewRepresentableContext<RiveButtonBridge>) {
        play ? riveView.play() : riveView.pause()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PlayDelegate, PauseDelegate, StopDelegate {
        private let rive: RiveButtonBridge
        
        init(_ rive: RiveButtonBridge) {
            self.rive = rive
        }
        
        func play(_ animationName: String) {
            rive.play = true
        }
        
        func pause(_ animationName: String) {
            rive.play = false
        }
        
        func stop(_ animationName: String) {
            rive.play = false
        }
    }
}
