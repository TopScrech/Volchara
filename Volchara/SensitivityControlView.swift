import SwiftUI

struct SensitivityControlView: View {
    @Binding var minAmplitude: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sensitivity")
                .font(.headline)
            
            HStack(spacing: 12) {
                Slider(value: $minAmplitude, in: 0.05 ... 0.9, step: 0.01)
                Text(String(format: "%.2f", minAmplitude))
                    .font(.body.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }
}
