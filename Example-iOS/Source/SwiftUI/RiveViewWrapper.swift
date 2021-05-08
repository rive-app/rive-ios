import SwiftUI
import RiveRuntime

struct UIRiveView: UIViewRepresentable {
    let resource: String
    @Binding var fit: Fit // Binding<Fit> = Binding.constant(Fit.Contain)
    @Binding var alignment: RiveRuntime.Alignment
    @Binding var loopCount: Int
    
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
        uiView.setFit(fit: fit)
        uiView.setAlignment(alignment: alignment)
    }
    
    // Constructs a coordinator for managing updating state
    func makeCoordinator() -> Coordinator {
        Coordinator(loopCount: $loopCount)
    }
    
}

// Coordinator between RiveView and UIRiveView
class Coordinator: NSObject, LoopDelegate {
    @Binding private var loopCount: Int
    
    init(loopCount: Binding<Int>) {
        self._loopCount = loopCount
    }
    
    func loop(_ animationName: String, type: Int) {
        loopCount += 1
    }
    
//    @Binding private var fit: Fit
//
//    init(fit: Binding<Fit>) {
//        self._fit = fit
//    }
}
