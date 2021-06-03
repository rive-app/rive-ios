import SwiftUI
import RiveRuntime

struct RiveSwitchBridge: UIViewRepresentable {
    let resource: String
    var fit: Fit = .fitContain
    var alignment: RiveRuntime.Alignment = .alignmentCenter
    var artboard: String? = nil
    var onAnimation: String = "On"
    var offAnimation: String = "Off"
    var startAnimation: String = "StartOff"
    
    /// Controls whether Rive is playing or paused
    @Binding var switchToOn: Bool
    @Binding var switchToOff: Bool
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: getRiveFile(resourceName: resource),
            fit: fit,
            alignment: alignment,
            artboard: artboard,
            animation: startAnimation
        )
        return riveView
    }

    func updateUIView(_ riveView: RiveView, context: UIViewRepresentableContext<RiveSwitchBridge>) {
        riveView.stop()
        if switchToOn {
            riveView.play(animationName: onAnimation)
        }
        if switchToOff {
            riveView.play(animationName: offAnimation)
        }
    }
    
    static func dismantleUIView(_ riveView: RiveView, coordinator: Self.Coordinator) {
        riveView.stop()
    }
}
