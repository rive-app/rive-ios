//
//  SplashScreen.swift
//  RiveExampleSPM
//
//  Created by Zachary Duncan on 7/1/22.
//

import SwiftUI
import RiveRuntime

struct SplashScreen: View {
    @State var isPlaying = true
    
    // MARK: ViewModels
    /// RiveViewModels are the main point of contact with the RiveRuntime. They are
    /// the bridge between the file and the image that displays.
    
    /// The file that this ViewModel controls only has one Animation, so
    /// we don't need to specify it by name. But we want to play it manually only
    /// after the View appears, so we turn off autoPlay.
    var riveLogo = RiveViewModel(fileName: "rive_animation_logo", autoPlay: false)
    
    /// This file only has one Animation also, and it can autoPlay, so all that
    /// is needed is the file name
    var tree = RiveViewModel(fileName: "windy_tree")
    
    /// This file has a StateMachine that reacts when we set its boolean input called "Play"
    var playButton = RiveViewModel(fileName: "play_pause", stateMachineName: "State Machine 1")
    
    /// This file has a StateMachine that will react when we trigger an input called "Trigger explosion"
    var confetti = RiveViewModel(fileName: "confetti", stateMachineName: "State Machine 1")
    
    /// This file has a StateMachine with Listeners that respond to touch. Listeners don't require
    /// any code to activate
    var rings = RiveViewModel(fileName: "interactive_rings", stateMachineName: "State Machine 1")
    
    var body: some View {
        ZStack {
            tree.view()
                .aspectRatio(contentMode: .fit)
            
            VStack {
                riveLogo.view()
                    .aspectRatio(contentMode: .fit)
                    .onAppear() {
                        riveLogo.play()
                    }
                
                Spacer().frame(width: 1.0)
            }
            
            VStack {
                Spacer().frame(width: 1.0)
                Spacer().frame(width: 1.0)
                
                ZStack {
                    playButton.view()
                        .padding(70)
                    
                    rings.view()
                        .aspectRatio(contentMode: .fit)
                        .opacity(0.5)
                        .onTapGesture { togglePlay() }
                        .onLongPressGesture { togglePlay() }
                }
                .padding(30)
            }
            
            VStack {
                confetti.view()
                    .onTapGesture {
                        if !riveLogo.isPlaying {
                            confetti.triggerInput("Trigger explosion")
                        }
                        riveLogo.play()
                    }
                
                Spacer().frame(width: 1.0)
            }
        }
        .ignoresSafeArea()
        .background(LinearGradient(colors: [.lightPurple, .darkPurple], startPoint: .top, endPoint: .bottom))
    }
    
    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            tree.play()
        } else {
            tree.pause()
        }
        playButton.setInput("Play", value: isPlaying)
    }
}

extension Color {
    static var lightPurple = Color(hue: 0.786, saturation: 0.528, brightness: 0.463)
    static var darkPurple = Color(hue: 0.748, saturation: 0.917, brightness: 0.189)
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
            .previewDevice("iPhone 13")
    }
}
