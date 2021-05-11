import SwiftUI
import RiveRuntime

struct RiveSwiftUIView: View {
    @ObservedObject private var riveController: RiveController = RiveController()
    
    var dismiss: () -> Void = {}
    @State private var loopCount: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                resource: "basketball",
                controller: riveController
//                loopAction: { name, type in
//                    loopCount += 1
//                },
//                playAction: { name in
//                    print("Playing \(name)")
//                },
//                pauseAction: { name in
//                    print("Pausing \(name)")
//                }
            )
            VStack {
                Text("Looped \(loopCount) times")
                    .foregroundColor(.blue)
                    .padding()
                HStack {
                    Button(action: { riveController.alignment = RiveRuntime.Alignment.TopLeft },
                           label: { Text("Top Left") })
                    Spacer()
                    Button(action: { riveController.alignment = RiveRuntime.Alignment.Center },
                           label: { Text("Center") })
                    Spacer()
                    Button(action: { riveController.alignment = RiveRuntime.Alignment.BottomRight },
                           label: { Text("Bottom Right") })
                }
                .padding()
                HStack {
                    Button(action: { riveController.fit = Fit.Contain },
                           label: { Text("Contain") })
                    Spacer()
                    Button(action: { riveController.fit = Fit.Cover },
                           label: { Text("Cover") })
                    Spacer()
                    Button(action: { riveController.fit = Fit.Fill },
                           label: { Text("Fill") })
                }
                .padding()
                HStack {
                    Button(action: {
                        if riveController.playback == Playback.play {
                            riveController.pause()
                        } else {
                            riveController.play()
                        }
                    },
                    label: {
                        switch riveController.playback {
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
