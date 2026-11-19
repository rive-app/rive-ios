import SwiftUI
import RiveRuntime

@main
struct PreviewMacOSApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                RiveViewModel(fileName: "magic_8-ball_v2").view()
            }
            .padding()
        }
    }
}
