import SwiftUI
import RiveRuntime

struct RiveButtonBridge: UIViewRepresentable {
    let resource: String
    var fit: Fit = .fitContain
    var alignment: RiveRuntime.Alignment = .alignmentCenter
    var artboard: String? = nil
    var animation: String? = nil
    
    /// Controls whether Rive is playing or paused
    @Binding var play: Bool
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        
        do {
            let riveView = try RiveView(
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
        catch {
            print(error)
            return RiveView()
        }
    }
    
    func updateUIView(_ riveView: RiveView, context: UIViewRepresentableContext<RiveButtonBridge>) {
        play ? try? riveView.play() : riveView.pause()
    }
    
    static func dismantleUIView(_ riveView: RiveView, coordinator: Self.Coordinator) {
        riveView.stop()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PlayDelegate, PauseDelegate, StopDelegate {
        private let rive: RiveButtonBridge
        
        init(_ rive: RiveButtonBridge) {
            self.rive = rive
        }
        
        func play(_ animationName: String, isStateMachine: Bool) {
            rive.play = true
        }
        
        func pause(_ animationName: String, isStateMachine: Bool) {
            rive.play = false
        }
        
        func stop(_ animationName: String, isStateMachine: Bool) {
            rive.play = false
        }
    }
}
