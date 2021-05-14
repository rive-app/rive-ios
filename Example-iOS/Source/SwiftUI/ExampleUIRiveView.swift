import SwiftUI
import RiveRuntime

struct ExampleUIRiveView: View {
    @ObservedObject private var riveController = RiveController(
        "artboard_animations",
        fit: Fit.cover
    )
    @State private var loopCount: Int = 0
    @State private var selection = 1
    
    var dismiss: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UIRiveView(
                controller: riveController
            )
            VStack {
                HStack(alignment: .center, spacing: 50) {
                    if #available(iOS 14.0, *) {
                        Menu {
                            ForEach(riveController.artboardNames(), id: \.self) { name in
                                Button {
                                    riveController.activeArtboard = name
                                } label: {
                                    Text(name)
                                }
                            }
                        } label: {
                            Text("Artboards")
                            Image(systemName: "square.and.pencil")
                        }
                        Menu {
                            ForEach(riveController.animationNames(), id: \.self) { name in
                                Button {
                                    riveController.playAnimation = name
                                } label: {
                                    Text(name)
                                }
                            }
                        } label: {
                            Text("Animations")
                            Image(systemName: "list.and.film")
                        }
                    }
                }
                .padding()
                HStack(alignment: .center, spacing: 50) {
                    if #available(iOS 14.0, *) {
                        Menu {
                            Button {
                                riveController.fit = .contain
                            } label: {
                                Text("Contain")
                            }
                            Button {
                                riveController.fit = Fit.cover
                            } label: {
                                Text("Cover")
                            }
                            Button {
                                riveController.fit = Fit.fill
                            } label: {
                                Text("Fill")
                            }
                        } label: {
                            Text("Fit")
                            Image(systemName: "crop")
                        }
                        Menu {
                            Button {
                                riveController.alignment = .topLeft
                            } label: {
                                Text("Top Left")
                            }
                            Button {
                                riveController.alignment = .topCenter
                            } label: {
                                Text("Top Center")
                            }
                            Button {
                                riveController.alignment = .topRight
                            } label: {
                                Text("Top Right")
                            }
                            Button {
                                riveController.alignment = .centerLeft
                            } label: {
                                Text("Left")
                            }
                            Button {
                                riveController.alignment = .center
                            } label: {
                                Text("Center")
                            }
                            Button {
                                riveController.alignment = .centerRight
                            } label: {
                                Text("Right")
                            }
                            Button {
                                riveController.alignment = .bottomLeft
                            } label: {
                                Text("Bottom Left")
                            }
                            Button {
                                riveController.alignment = .bottomCenter
                            } label: {
                                Text("Bottom Center")
                            }
                            Button {
                                riveController.alignment = .bottomRight
                            } label: {
                                Text("Bottom Right")
                            }
                        } label: {
                            Text("Alignment")
                            Image(systemName: "square.dashed")
                        }
                    }
                }
                .padding()
                HStack {
                    Button {
                        if riveController.playback == Playback.play {
                            riveController.pause()
                        } else {
                            riveController.play()
                        }
                    } label: {
                        switch riveController.playback {
                        case .play:
                            Image(systemName: "pause.circle")
                            Text("Pause")
                        case .pause, .stop:
                            Image(systemName: "play.circle")
                            Text("Play")
                        }
                    }
                    Spacer()
                    Button(action: dismiss, label: {
                        Image(systemName: "x.circle")
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
        ExampleUIRiveView()
    }
}
