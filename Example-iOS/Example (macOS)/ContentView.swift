import SwiftUI
import RiveRuntime

@MainActor
struct ContentView: View {
    var body: some View {
        AsyncRiveUIViewRepresentable {
            let worker = try await Worker()
            let file = try await File(source: .local("tkl-keyboard", .main), worker: worker)
            let artboard = try await file.createArtboard("TKL Keyboard")
            return try await Rive(
                file: file,
                artboard: artboard,
                fit: .layout(scaleFactor: .automatic)
            )
        }
        .keyboardFocused(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
