import SwiftUI
import RiveRuntime

struct RiveSwiftUIView: View {
    var dismiss: () -> Void = {}
    @State private var isPlaying: Bool = true
    @State private var fit: Fit = Fit.Cover
    @State private var alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                resource: "off_road_car_blog",
                fit: $fit,
                alignment: $alignment
            )
            VStack {
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
