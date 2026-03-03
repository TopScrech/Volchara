import SwiftUI

struct ActionButtonsView: View {
    let isListening: Bool
    let toggleAction: () -> Void
    let testAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(
                isListening ? "Stop Listening" : "Start Listening",
                systemImage: isListening ? "stop.circle" : "waveform",
                action: toggleAction
            )
            .buttonStyle(.borderedProminent)
            
            Button("Test Slap", systemImage: "hand.tap", action: testAction)
                .buttonStyle(.bordered)
        }
    }
}
