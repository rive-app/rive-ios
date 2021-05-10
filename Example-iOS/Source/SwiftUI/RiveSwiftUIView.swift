import SwiftUI
import RiveRuntime

struct RiveSwiftUIView: View {
    var dismiss: () -> Void = {}
    @State private var playback: Playback = Playback.play
    @State private var fit: Fit = Fit.Cover
    @State private var alignment: RiveRuntime.Alignment = RiveRuntime.Alignment.Center
    @State private var loopCount: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                resource: "basketball",
                fit: fit,
                alignment: alignment,
                playback: playback,
                loopAction: { name, type in
                    loopCount += 1
                },
                playAction: { name in
                    print("Playing \(name)")
                },
                pauseAction: { name in
                    print("Pausing \(name)")
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
                    Button(action: {
                        if playback == Playback.play {
                            playback = Playback.pause
                        } else {
                            playback = Playback.play
                        }
                    },
                    label: {
                        switch playback {
                        case .play:
                            Text("Pause")
                        case .pause, .stop:
                            Text("Play")
                        }
                    })

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
