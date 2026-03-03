import SwiftUI

struct ModePickerView: View {
    @Binding var selectedMode: SoundMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.headline)
            
            Picker("Mode", selection: $selectedMode) {
                ForEach(SoundMode.allCases) {
                    Text($0.title)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
