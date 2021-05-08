import SwiftUI
import RiveRuntime

struct RiveSwiftUIView: View {
    var dismiss: () -> Void = {}
    @State private var isPlaying: Bool = true
    @State private var fit: Fit = Fit.Cover
    @State private var alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    @State private var loopCount: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                resource: "basketball",
                fit: fit,
                alignment: alignment,
                loopAction: { name, type in
                    loopCount += 1
                }
            )
            VStack {
                Text("Looped \(loopCount) times")
                    .foregroundColor(.blue)
                    .padding()
                HStack {
                    Button(action: { alignment = RiveRuntime.Alignment.TopLeft },
                           label: { Text("Top Left") })
                    Spacer()
                    Button(action: { alignment = RiveRuntime.Alignment.Center },
                           label: { Text("Center") })
                    Spacer()
                    Button(action: { alignment = RiveRuntime.Alignment.BottomRight },
                           label: { Text("Bottom Right") })
                }
                .padding()
                HStack {
                    Button(action: { fit = Fit.Contain },
                           label: { Text("Contain") })
                    Spacer()
                    Button(action: { fit = Fit.Cover },
                           label: { Text("Cover") })
                    Spacer()
                    Button(action: { fit = Fit.Fill },
                           label: { Text("Fill") })
                }
                .padding()
                HStack {
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/,
                           label: { Text(isPlaying ? "Pause" : "Play") })
                    Spacer()
                    Button(action: dismiss, label: {
                        Text("Dismiss")
                    })
                }
                .padding()
            }
            .background(Color.init(white: 0, opacity: 0.75))
        }
    }
}

struct RiveSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        RiveSwiftUIView(dismiss: {})
    }
}
