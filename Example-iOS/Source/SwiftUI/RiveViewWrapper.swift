import SwiftUI
import RiveRuntime

struct UIRiveView: UIViewRepresentable {
    let resource: String
    @Binding var fit: Fit // Binding<Fit> = Binding.constant(Fit.Contain)
    @Binding var alignment: RiveRuntime.Alignment
    
    // Constructs the view
    func makeUIView(context: Context) -> RiveView {
        // print("Making Rive View")
        let riveView = RiveView(riveFile: getRiveFile(resourceName: resource))
        riveView.setFit(fit: Fit.Contain)
        riveView.setAlignment(alignment: alignment)
        return riveView
    }
 
    // Called when a bound variable changes state
    func updateUIView(_ uiView: RiveView, context: Context) {
        uiView.setFit(fit: fit)
        uiView.setAlignment(alignment: alignment)
    }
    
    // Constructs a coordinator for managing updating state
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self, fit: fit)
//    }
    
}
