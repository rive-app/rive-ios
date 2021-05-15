import SwiftUI
import RiveRuntime

struct RiveProgressBarBridge: UIViewRepresentable {
    let resource: String = "life_bar"
    var fit: Fit = .fitFill
    var alignment: RiveRuntime.Alignment = .alignmentCenter
    var stateMachine: String = "Life Machine"
    
    @Binding var health: Double
    
    /// The inputs
    private let input100Name = "100"
    private let input75Name = "75"
    private let input50Name = "50"
    private let input25Name = "25"
    private let input0Name = "0"
    
    /// Constructs the view
    func makeUIView(context: Context) -> RiveView {
        let riveView = RiveView(
            riveFile: getRiveFile(resourceName: resource),
            fit: fit,
            alignment: alignment,
            autoplay: true,
            stateMachine: stateMachine
        )
        
        // Always keep the 100 set; just how this state machine works
        riveView.setBooleanState(stateMachine, inputName: input100Name, value: true)
        
        return riveView
    }

    
    
    func updateUIView(_ riveView: RiveView, context: UIViewRepresentableContext<RiveProgressBarBridge>) {
        riveView.setBooleanState(stateMachine, inputName: input75Name, value: health < 100)
        riveView.setBooleanState(stateMachine, inputName: input50Name, value: health <= 66)
        riveView.setBooleanState(stateMachine, inputName: input25Name, value: health <= 33)
        riveView.setBooleanState(stateMachine, inputName: input0Name, value: health <= 0)
    }
}
