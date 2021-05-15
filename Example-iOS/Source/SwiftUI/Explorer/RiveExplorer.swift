import SwiftUI
import RiveRuntime

struct RiveExplorer: View {
    @ObservedObject private var riveController = RiveController(
        "artboard_animations",
        fit: Fit.fitCover
    )
    @State private var loopCount: Int = 0
    @State private var selection = 1
    
    var dismiss: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RiveExplorerBridge(
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
                                riveController.fit = .fitContain
                            } label: {
                                Text("Contain")
                            }
                            Button {
                                riveController.fit = .fitCover
                            } label: {
                                Text("Cover")
                            }
                            Button {
                                riveController.fit = .fitFill
                            } label: {
                                Text("Fill")
                            }
                        } label: {
                            Text("Fit")
                            Image(systemName: "crop")
                        }
                        Menu {
                            Button {
                                riveController.alignment = .alignmentTopLeft
                            } label: {
                                Text("Top Left")
                            }
                            Button {
                                riveController.alignment = .alignmentTopCenter
                            } label: {
                                Text("Top Center")
                            }
                            Button {
                                riveController.alignment = .alignmentTopRight
                            } label: {
                                Text("Top Right")
                            }
                            Button {
                                riveController.alignment = .alignmentCenterLeft
                            } label: {
                                Text("Left")
                            }
                            Button {
                                riveController.alignment = .alignmentCenter
                            } label: {
                                Text("Center")
                            }
                            Button {
                                riveController.alignment = .alignmentCenterRight
                            } label: {
                                Text("Right")
                            }
                            Button {
                                riveController.alignment = .alignmentBottomLeft
                            } label: {
                                Text("Bottom Left")
                            }
                            Button {
                                riveController.alignment = .alignmentBottomCenter
                            } label: {
                                Text("Bottom Center")
                            }
                            Button {
                                riveController.alignment = .alignmentBottomRight
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
        RiveExplorer()
    }
}
