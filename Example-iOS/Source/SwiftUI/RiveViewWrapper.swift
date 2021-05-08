import SwiftUI
import RiveRuntime

typealias LoopAction = ((String, Int) -> Void)?

struct UIRiveView: UIViewRepresentable {
    let resource: String
    var fit: Fit = Fit.Contain
    var alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    var loopAction: LoopAction = nil
    
    // Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(riveFile: getRiveFile(resourceName: resource))
        riveView.setFit(fit: fit)
        riveView.setAlignment(alignment: alignment)
        
        // Set the delegates
        riveView.loopDelegate = context.coordinator

        return riveView
    }
 
    // Called when a bound variable changes state
    func updateUIView(_ uiView: RiveView, context: Context) {
        print("updateUI")
        uiView.setFit(fit: fit)
        uiView.setAlignment(alignment: alignment)
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        // Coordinator(loopCount: $loopCount)
        Coordinator(loopAction: loopAction)
    }
    
}

// Coordinator between RiveView and UIRiveView
class Coordinator: NSObject, LoopDelegate {
    private var loopAction: LoopAction
    
    init(loopAction: LoopAction) {
        self.loopAction = loopAction
    }
    
    func loop(_ animationName: String, type: Int) {
            loopAction?(animationName, type)
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
